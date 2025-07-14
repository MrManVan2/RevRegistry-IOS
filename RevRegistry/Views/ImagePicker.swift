import SwiftUI
import PhotosUI
import AVFoundation

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Camera Permission Helper
struct CameraPermissionView: View {
    @Binding var showingImagePicker: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        EmptyView()
            .confirmationDialog("Add Photo", isPresented: $showingImagePicker) {
                Button("Camera") {
                    requestCameraPermission()
                }
                
                Button("Photo Library") {
                    requestPhotoLibraryPermission()
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
    }
    
    private func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            sourceType = .camera
            showingImagePicker = true
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        sourceType = .camera
                        showingImagePicker = true
                    } else {
                        showPermissionAlert(for: "camera")
                    }
                }
            }
            
        case .denied, .restricted:
            showPermissionAlert(for: "camera")
            
        @unknown default:
            showPermissionAlert(for: "camera")
        }
    }
    
    private func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            sourceType = .photoLibrary
            showingImagePicker = true
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        sourceType = .photoLibrary
                        showingImagePicker = true
                    } else {
                        showPermissionAlert(for: "photo library")
                    }
                }
            }
            
        case .denied, .restricted:
            showPermissionAlert(for: "photo library")
            
        @unknown default:
            showPermissionAlert(for: "photo library")
        }
    }
    
    private func showPermissionAlert(for accessType: String) {
        permissionAlertMessage = "Please enable \(accessType) access in Settings to use this feature."
        showingPermissionAlert = true
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}