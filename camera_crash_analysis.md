# Camera Crash Analysis & Solutions

## Current State Assessment

### Infrastructure Found ✅
- Image upload services in `VehicleService.swift` and `ExpenseService.swift`
- Cloudinary integration for image storage
- Database schema supports receipt and vehicle images
- API endpoints for image uploads

### Camera Implementation Status ❌
- **No native iOS camera picker implementation found**
- No `UIImagePickerController` or `PHPickerViewController` usage
- No camera permission handling in Swift code
- Camera functionality likely implemented via web components (causing crashes)

## Root Cause: iOS WKWebView Camera Issues

Based on Apple Developer Forums research, the crashes are likely caused by:

### 1. WebView Camera API Crashes (iOS 17+)
```javascript
// THIS CRASHES ON iOS 17+
navigator.mediaDevices.getUserMedia({
  video: true,
  audio: true  // ← Requesting both simultaneously causes crash
});
```

### 2. File Input Camera Crashes
```html
<!-- THIS CRASHES IN WKWebView -->
<input type="file" accept="image/*" capture="camera">
```

### 3. UIImagePickerController Modal Issues
```swift
// PROBLEMATIC CODE THAT CAUSES CRASHES
@implementation UIImagePickerController (custom)
- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationCustom; // ← This breaks camera
}
@end
```

## Immediate Solutions

### Solution 1: Fix Web-Based Camera (if using WKWebView)

#### Request Permissions Separately:
```javascript
// SAFE: Request camera first
async function requestCameraOnly() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: false  // ← No audio to avoid crash
    });
    return stream;
  } catch (error) {
    console.error('Camera permission failed:', error);
    throw error;
  }
}

// Then request microphone separately if needed
async function requestMicrophoneOnly() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: false
    });
    return stream;
  } catch (error) {
    console.error('Microphone permission failed:', error);
    throw error;
  }
}
```

#### Pre-warm Camera Device (Swift workaround):
```swift
// Add this before any camera operations
func prewarmCamera() {
    let _ = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
}
```

### Solution 2: Implement Native iOS Camera (Recommended)

Create a proper native iOS camera implementation:

#### 1. Add Camera Permissions to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture vehicle photos and receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
```

#### 2. Create ImagePicker Implementation:
```swift
import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
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
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
```

#### 3. Add Camera ActionSheet to Views:
```swift
// Add to VehicleDetailView or ExpenseListView
.actionSheet(isPresented: $showingImagePicker) {
    ActionSheet(
        title: Text("Select Image"),
        buttons: [
            .default(Text("Camera")) {
                checkCameraPermission {
                    sourceType = .camera
                    showingImagePicker = true
                }
            },
            .default(Text("Photo Library")) {
                sourceType = .photoLibrary
                showingImagePicker = true
            },
            .cancel()
        ]
    )
}
```

## Files That Need Updates

### Swift Files to Create:
- `RevRegistry/Views/ImagePicker.swift` - Native camera implementation
- `RevRegistry/Services/CameraService.swift` - Camera permission handling

### Swift Files to Update:
- `RevRegistry/Views/VehicleDetailView.swift` - Add vehicle photo capture
- `RevRegistry/Views/ExpenseListView.swift` - Add receipt capture
- `RevRegistry/Services/VehicleService.swift` - Connect to camera
- `RevRegistry/Services/ExpenseService.swift` - Connect to camera

### Configuration Updates:
- `RevRegistry/Info.plist` - Add camera permissions
- Remove any problematic UIImagePickerController category implementations

## Testing Priorities

1. **Test on actual iOS devices** (crashes don't reproduce in simulator)
2. **Test iOS 17+ specifically** (known problematic versions)
3. **Test both camera and photo library selection**
4. **Verify permissions are requested properly**

## Next Steps

1. Identify if you're using WKWebView for camera functionality
2. Implement native iOS camera picker (recommended)
3. Remove any problematic web-based camera code
4. Test thoroughly on physical iOS devices

The crashes are likely due to known iOS bugs with web-based camera access. Implementing native iOS camera functionality will provide a much more stable and user-friendly experience.