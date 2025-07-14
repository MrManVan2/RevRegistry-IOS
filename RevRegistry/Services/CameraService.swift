import SwiftUI
import AVFoundation
import PhotosUI

@MainActor
class CameraService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Camera Availability
    
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    // MARK: - Permission Checking
    
    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func checkPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { status in
                    let granted = status == .authorized || status == .limited
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Image Processing
    
    func processImageForUpload(_ image: UIImage, maxSize: CGSize = CGSize(width: 1024, height: 1024)) -> Data? {
        // Resize image if needed
        let resizedImage = resizeImage(image, to: maxSize)
        
        // Convert to JPEG with compression
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Upload Helpers
    
    func uploadVehicleImage(_ image: UIImage, vehicleId: String, vehicleService: VehicleService) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let imageData = processImageForUpload(image) else {
                throw CameraServiceError.imageProcessingFailed
            }
            
            let imageUrl = try await vehicleService.uploadVehicleImage(vehicleId: vehicleId, imageData: imageData)
            
            // Update vehicle with new image URL if needed
            // This would require updating the vehicle service to handle image URL updates
            
        } catch {
            errorMessage = "Failed to upload vehicle image: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func uploadReceiptImage(_ image: UIImage, expenseId: String, expenseService: ExpenseService) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let imageData = processImageForUpload(image) else {
                throw CameraServiceError.imageProcessingFailed
            }
            
            let imageUrl = try await expenseService.uploadReceipt(expenseId: expenseId, imageData: imageData)
            
            // Handle successful upload
            
        } catch {
            errorMessage = "Failed to upload receipt: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Camera Service Errors

enum CameraServiceError: Error, LocalizedError {
    case imageProcessingFailed
    case cameraNotAvailable
    case photoLibraryNotAvailable
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the selected image"
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .photoLibraryNotAvailable:
            return "Photo library is not available"
        case .permissionDenied:
            return "Camera or photo library permission was denied"
        }
    }
}