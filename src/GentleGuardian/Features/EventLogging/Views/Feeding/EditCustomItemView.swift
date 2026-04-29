import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Form for creating or editing a `CustomItem` (formula or solid food).
///
/// Captures a name and an optional photo. Photos are resized client-side to
/// keep peer-to-peer attachment payloads small (~150 KB JPEG, max 512 px).
struct EditCustomItemView: View {

    // MARK: - Properties

    let childId: String
    let category: CustomItemCategory
    let repository: CustomItemRepository
    let attachmentLoader: CustomItemAttachmentLoader
    /// Existing item when editing; `nil` for create mode.
    let existing: CustomItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var name: String = ""
    @State private var existingToken: String?
    @State private var pendingImage: PlatformImage?
    @State private var clearAttachment: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    #if os(iOS)
    @State private var photoSelection: PhotosPickerItem?
    #endif

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()
            ScrollView {
                VStack(spacing: GGSpacing.lg) {
                    nameSection
                    photoSection
                    if let errorMessage {
                        errorBanner(message: errorMessage)
                    }
                    GGButton(
                        existing == nil ? "Add" : "Save",
                        variant: .primary,
                        icon: "checkmark.circle",
                        isLoading: isSaving,
                        isDisabled: !isValid
                    ) {
                        Task { await save() }
                    }
                }
                .padding(GGSpacing.pageInsets)
                .padding(.bottom, GGSpacing.xxl)
            }
        }
        .navigationTitle(existing == nil
            ? (category == .formula ? "Add Formula" : "Add Food")
            : (category == .formula ? "Edit Formula" : "Edit Food"))
        .inlineNavigationBarTitle()
        .onAppear(perform: hydrateFromExisting)
        #if os(iOS)
        .onChange(of: photoSelection) { _, newItem in
            guard let newItem else { return }
            Task { await loadPickedImage(item: newItem) }
        }
        #endif
    }

    // MARK: - Sections

    private var nameSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text(category == .formula ? "Formula Name" : "Food Name")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)
                GGTextField(
                    category == .formula ? "e.g., Similac Pro-Advance" : "e.g., Sweet potato puree",
                    text: $name,
                    icon: category == .formula ? "drop" : "fork.knife"
                )
            }
        }
    }

    private var photoSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Photo (optional)")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                photoPreview

                photoActions
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let pendingImage {
            Image(platformImage: pendingImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if !clearAttachment, let existingToken,
                  let cached = attachmentLoader.image(for: existingToken) {
            Image(platformImage: cached)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.onSurface.opacity(0.06))
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .overlay {
                    VStack(spacing: GGSpacing.xs) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(colors.onSurface.opacity(0.4))
                        Text("No photo")
                            .font(.ggBodySmall)
                            .foregroundStyle(colors.onSurface.opacity(0.5))
                    }
                }
        }
    }

    @ViewBuilder
    private var photoActions: some View {
        HStack(spacing: GGSpacing.sm) {
            #if os(iOS)
            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(hasAnyImage ? "Replace" : "Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.ggLabelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: GGSpacing.minimumTouchTarget)
                    .background(colors.secondaryContainer)
                    .foregroundStyle(colors.onSecondaryContainer)
                    .clipShape(Capsule())
            }
            #elseif os(macOS)
            GGButton(
                hasAnyImage ? "Replace" : "Choose Photo",
                variant: .secondary,
                icon: "photo.on.rectangle"
            ) {
                pickImageMacOS()
            }
            #endif

            if hasAnyImage {
                GGButton("Remove", variant: .tertiary, icon: "xmark.circle") {
                    pendingImage = nil
                    clearAttachment = true
                    #if os(iOS)
                    photoSelection = nil
                    #endif
                }
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(colors.error)
            Text(message)
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    // MARK: - State Helpers

    private var hasAnyImage: Bool {
        if pendingImage != nil { return true }
        if clearAttachment { return false }
        if let existingToken, !existingToken.isEmpty { return true }
        return false
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func hydrateFromExisting() {
        guard let existing else { return }
        if name.isEmpty { name = existing.name }
        existingToken = existing.attachmentToken
    }

    // MARK: - Photo Loading

    #if os(iOS)
    private func loadPickedImage(item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Couldn't read that photo."
                return
            }
            pendingImage = image
            clearAttachment = false
        } catch {
            errorMessage = "Couldn't load the selected photo."
        }
    }
    #elseif os(macOS)
    private func pickImageMacOS() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url,
           let image = NSImage(contentsOf: url) {
            pendingImage = image
            clearAttachment = false
        }
    }
    #endif

    // MARK: - Save

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var nextToken: String? = clearAttachment ? nil : existingToken

        // Upload new attachment if the user picked one.
        if let pendingImage {
            do {
                let data = try jpegData(from: pendingImage, maxDimension: 512, targetBytes: 150_000)
                let token = try await DittoManager.shared.newAttachment(
                    data: data,
                    metadata: ["category": category.rawValue, "name": trimmed]
                )
                // Dispose any previous attachment we are replacing.
                if let existingToken, !existingToken.isEmpty {
                    await DittoManager.shared.disposeAttachment(token: existingToken)
                    attachmentLoader.evict(token: existingToken)
                }
                nextToken = token
            } catch {
                errorMessage = "Couldn't save the photo. Please try again."
                return
            }
        } else if clearAttachment, let existingToken, !existingToken.isEmpty {
            // User chose Remove on an existing image.
            await DittoManager.shared.disposeAttachment(token: existingToken)
            attachmentLoader.evict(token: existingToken)
        }

        let item = CustomItem(
            id: existing?.id ?? UUID().uuidString,
            childId: childId,
            category: category,
            name: trimmed,
            defaultQuantity: existing?.defaultQuantity,
            defaultQuantityUnit: existing?.defaultQuantityUnit,
            createdAt: existing?.createdAt ?? Date(),
            isArchived: false,
            isSeeded: existing?.isSeeded ?? false,
            attachmentToken: nextToken
        )

        do {
            if existing == nil {
                try await repository.insert(item: item)
            } else {
                try await repository.update(item: item)
            }
            dismiss()
        } catch {
            errorMessage = "Couldn't save. Please try again."
        }
    }

    // MARK: - Image Encoding

    /// Resizes and JPEG-encodes the image, stepping the quality down until the
    /// payload fits below `targetBytes` (best-effort).
    private func jpegData(
        from image: PlatformImage,
        maxDimension: CGFloat,
        targetBytes: Int
    ) throws -> Data {
        let resized = resize(image: image, maxDimension: maxDimension)
        var quality: CGFloat = 0.85
        while quality >= 0.4 {
            if let data = encodeJPEG(image: resized, quality: quality), data.count <= targetBytes {
                return data
            }
            quality -= 0.1
        }
        if let data = encodeJPEG(image: resized, quality: 0.4) { return data }
        throw NSError(
            domain: "EditCustomItemView",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Could not encode image."]
        )
    }

    private func resize(image: PlatformImage, maxDimension: CGFloat) -> PlatformImage {
        #if os(iOS)
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        #elseif os(macOS)
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let target = NSSize(width: size.width * scale, height: size.height * scale)
        let resized = NSImage(size: target)
        resized.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: target),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        return resized
        #endif
    }

    private func encodeJPEG(image: PlatformImage, quality: CGFloat) -> Data? {
        #if os(iOS)
        return image.jpegData(compressionQuality: quality)
        #elseif os(macOS)
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
        #endif
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
