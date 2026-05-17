import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct ProductInputView: View {
    @State private var productTitle: String
    @State private var productDescription: String
    @State private var productWeight: String
    @State private var productSize: String
    @State private var productExtraDetails: String
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImage: UIImage?
    @State private var selectedImages: [UIImage]
    @State private var selectedImageIndex: Int = 0
    @State private var showCamera = false
    @State private var navigateToWorkflow = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showClearImagesConfirmation = false
    @State private var showRemoveImageConfirmation = false
    @State private var pendingRemoveImageIndex: Int?
    @AppStorage("packwise_is_light_theme") private var isLightTheme = false

    init(
        initialTitle: String = "",
        initialDescription: String = "",
        initialWeight: String = "",
        initialSize: String = "",
        initialExtraDetails: String = "",
        initialImage: UIImage? = nil
    ) {
        _productTitle = State(initialValue: initialTitle)
        _productDescription = State(initialValue: initialDescription)
        _productWeight = State(initialValue: initialWeight)
        _productSize = State(initialValue: initialSize)
        _productExtraDetails = State(initialValue: initialExtraDetails)
        _selectedImage = State(initialValue: initialImage)
        _selectedImages = State(initialValue: initialImage.map { [$0] } ?? [])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroSection
                    uploadCard
                    imageOptionsSection
                    photoPreparationGuideCard
                    productDetailsCard
                    privacyNote

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, selectedImage == nil ? 28 : 112)
            }

            if selectedImage != nil {
                stickyAIActionButton
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Ürün Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isLightTheme.toggle()
                    }
                } label: {
                    Image(systemName: isLightTheme ? "moon.fill" : "sun.max.fill")
                        .font(.caption.bold())
                        .foregroundStyle(isLightTheme ? .white : .yellow)
                        .frame(width: 32, height: 32)
                        .background(
                            isLightTheme
                            ? Color.black.opacity(0.18)
                            : Color.white.opacity(0.10)
                        )
                        .clipShape(Circle())
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AnalysisHistoryView()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Geçmiş")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(isLightTheme ? Color(red: 0.05, green: 0.10, blue: 0.20) : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isLightTheme ? Color.white.opacity(0.72) : Color.white.opacity(0.10))
                    .clipShape(Capsule())
                }
            }
        }
        .navigationDestination(isPresented: $navigateToWorkflow) {
            AnalysisWorkflowView(
                productTitle: productTitle,
                productDescription: enrichedProductDescription,
                productImage: selectedImage,
                productImages: selectedImages,
                weight: productWeight,
                size: productSize
            )
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedItems) {
            Task {
                var loadedImages: [UIImage] = []

                for item in selectedItems.prefix(4) {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        loadedImages.append(uiImage.optimizedForAIUpload(maxDimension: 1400))
                    }
                }

                await MainActor.run {
                    selectedImages = loadedImages
                    selectedImageIndex = 0
                    selectedImage = loadedImages.first
                }
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            guard let newImage else { return }

            if selectedImages.isEmpty {
                selectedImages = [newImage]
                selectedImageIndex = 0
                return
            }

            if let existingIndex = selectedImages.firstIndex(where: { $0 === newImage }) {
                selectedImageIndex = existingIndex
                return
            }

            if selectedImages.count < 4 {
                selectedImages.append(newImage)
                selectedImageIndex = selectedImages.count - 1
            } else {
                selectedImages[selectedImageIndex] = newImage
            }
        }
        .alert("Uyarı", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Görseller kaldırılsın mı?", isPresented: $showClearImagesConfirmation) {
            Button("Vazgeç", role: .cancel) {}
            Button("Kaldır", role: .destructive) {
                clearAllImages()
            }
        } message: {
            Text("Eklediğin tüm fotoğraflar kaldırılacak. Bu işlem geri alınamaz.")
        }
        .alert("Bu fotoğraf silinsin mi?", isPresented: $showRemoveImageConfirmation) {
            Button("Vazgeç", role: .cancel) {
                pendingRemoveImageIndex = nil
            }
            Button("Sil", role: .destructive) {
                if let pendingRemoveImageIndex {
                    removeImage(at: pendingRemoveImageIndex)
                }
                pendingRemoveImageIndex = nil
            }
        } message: {
            Text("Seçili fotoğraf listeden kaldırılacak.")
        }
    }


    private var primaryTextColor: Color {
        isLightTheme ? Color(red: 0.04, green: 0.08, blue: 0.16) : .white
    }

    private var secondaryTextColor: Color {
        isLightTheme ? Color(red: 0.20, green: 0.27, blue: 0.38) : .white.opacity(0.70)
    }

    private var mutedTextColor: Color {
        isLightTheme ? Color(red: 0.38, green: 0.45, blue: 0.56) : .white.opacity(0.55)
    }

    private var cardBackgroundColor: Color {
        isLightTheme ? Color.white.opacity(0.78) : Color.white.opacity(0.07)
    }

    private var cardStrokeColor: Color {
        isLightTheme ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: isLightTheme
                ? [
                    Color(red: 0.91, green: 0.97, blue: 1.00),
                    Color(red: 0.82, green: 0.93, blue: 1.00),
                    Color(red: 0.96, green: 0.98, blue: 1.00)
                ]
                : [
                    Color(red: 0.02, green: 0.05, blue: 0.13),
                    Color(red: 0.03, green: 0.12, blue: 0.27),
                    Color(red: 0.05, green: 0.08, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: isLightTheme
                ? [
                    Color.yellow.opacity(0.22),
                    Color.cyan.opacity(0.14),
                    Color.clear
                ]
                : [
                    Color.cyan.opacity(0.22),
                    Color.blue.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 410
            )

            Circle()
                .fill(isLightTheme ? Color.yellow.opacity(0.20) : Color.blue.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -130, y: -150)

            Circle()
                .fill(isLightTheme ? Color.cyan.opacity(0.16) : Color.purple.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 85)
                .offset(x: 120, y: 260)
        }
        .ignoresSafeArea()
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Ürününü")
                    .foregroundStyle(primaryTextColor)

                Text("Görsel")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("ile Başlat")
                    .foregroundStyle(primaryTextColor)
            }
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.75)
            .lineLimit(1)

            Text("Ürün görselini yükle, ek bilgileri yaz ve AI risk analizini başlat.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(secondaryTextColor)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 0)
        .padding(.bottom, 2)
    }

    private var photoPreparationGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.mint.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: "camera.macro.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.mint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Fotoğraf Hazırlık Rehberi")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text("Daha doğru risk, hasar ve iade analizi için fotoğrafı yüklemeden önce kontrol et.")
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("Önemli+")
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.mint)
                    .clipShape(Capsule())
            }

            VStack(spacing: 10) {
                photoPreparationRow(
                    icon: "viewfinder",
                    title: "Ürün tek başına görünsün",
                    text: "Arka plan sade olsun; AI ürünü başka nesnelerle karıştırmasın."
                )

                photoPreparationRow(
                    icon: "ruler.fill",
                    title: "Ölçü ve detay algısı ver",
                    text: "Mümkünse yakın detay, etiket, model veya kusur fotoğrafı ekle."
                )

                photoPreparationRow(
                    icon: "shippingbox.fill",
                    title: "Kargo riskini göster",
                    text: "Kırılgan, elektronik veya sıvı ürünlerde kutu/paketleme detayı analizi güçlendirir."
                )
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.mint)
                    .padding(.top, 2)

                Text("İpucu: En iyi sonuç için ana fotoğraf + 1 detay + 1 ölçü/etiket fotoğrafı yükle.")
                    .font(.caption)
                    .foregroundStyle(mutedTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(isLightTheme ? Color.white.opacity(0.62) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isLightTheme
                ? [Color.white.opacity(0.82), Color.mint.opacity(0.10)]
                : [Color.white.opacity(0.07), Color.mint.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mint.opacity(isLightTheme ? 0.18 : 0.12), lineWidth: 1)
        )
    }

    private func photoPreparationRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(.mint)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(primaryTextColor)

                Text(text)
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(11)
        .background(isLightTheme ? Color.white.opacity(0.58) : Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var uploadCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(cardBackgroundColor)
                    .frame(height: 190)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(cardStrokeColor, lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 24)
                    .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [8, 7]))
                    .foregroundStyle(selectedImage == nil ? Color.cyan.opacity(0.45) : Color.green.opacity(0.55))
                    .padding(16)

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 190)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.42)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                        )

                    VStack {
                        Spacer()

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)

                            Text("Görsel hazır")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                        .padding(.bottom, 14)
                    }
                } else {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.20))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                                )

                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(spacing: 7) {
                            Text("Ürün Görseli Ekle")
                                .font(.headline.bold())
                                .foregroundStyle(primaryTextColor)

                            Text("Sadece ürün görseli ile devam edebilirsin.")
                                .font(.subheadline)
                                .foregroundStyle(mutedTextColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }

            if selectedImage != nil {
                if !selectedImages.isEmpty {
                    thumbnailStrip
                }

                Button {
                    showClearImagesConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Görseli Kaldır")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var thumbnailStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Eklenen Fotoğraflar")
                        .font(.caption.bold())
                        .foregroundStyle(mutedTextColor)

                    Text("Fotoğrafa dokunarak ana görsel yapabilirsin.")
                        .font(.caption2)
                        .foregroundStyle(mutedTextColor.opacity(0.85))
                }

                Spacer()

                Text("\(selectedImages.count)/4")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        thumbnailItem(image: image, index: index)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 2)
    }

    private func thumbnailItem(image: UIImage, index: Int) -> some View {
        let isPrimary = selectedImageIndex == index

        return ZStack(alignment: .topTrailing) {
            Button {
                makeImagePrimary(at: index)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 78, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isPrimary ? Color.cyan : cardStrokeColor, lineWidth: isPrimary ? 2.4 : 1)
                        )
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.48)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        )

                    Text(isPrimary ? "Ana" : "Ana Yap")
                        .font(.caption2.bold())
                        .foregroundStyle(isPrimary ? .black : .white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(isPrimary ? Color.cyan : Color.black.opacity(0.48))
                        .clipShape(Capsule())
                        .padding(6)
                }
            }
            .buttonStyle(.plain)

            Button {
                pendingRemoveImageIndex = index
                showRemoveImageConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.red.opacity(0.92))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(5)
        }
        .accessibilityLabel(isPrimary ? "Ana fotoğraf" : "Ana fotoğraf yap")
    }

    private func makeImagePrimary(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImageIndex = index
        selectedImage = selectedImages[index]
    }

    private func clearAllImages() {
        selectedImage = nil
        selectedImages = []
        selectedItems = []
        selectedImageIndex = 0
        pendingRemoveImageIndex = nil
    }

    private func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }

        selectedImages.remove(at: index)

        if selectedImages.isEmpty {
            selectedImage = nil
            selectedItems = []
            selectedImageIndex = 0
            return
        }

        if selectedImageIndex == index {
            selectedImageIndex = min(index, selectedImages.count - 1)
        } else if selectedImageIndex > index {
            selectedImageIndex -= 1
        }

        selectedImage = selectedImages[selectedImageIndex]
    }

    private var imageOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Görsel Ekleme Seçenekleri")
                .font(.title3.bold())
                .foregroundStyle(primaryTextColor)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 4, matching: .images) {
                    optionCard(
                        icon: "photo.fill.on.rectangle.fill",
                        title: "Galeriden Seç",
                        subtitle: "En fazla 4 fotoğraf seç.",
                        color: .blue
                    )
                }

                Button {
                    openCameraSafely()
                } label: {
                    optionCard(
                        icon: "camera.fill",
                        title: "Kamera ile Çek",
                        subtitle: "Anında fotoğraf çek ve yükle.",
                        color: .green
                    )
                }
            }
        }
    }

    private func optionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.20))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(primaryTextColor)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(mutedTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .padding(.horizontal, 10)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    private var productDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: "text.badge.plus")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ürün Hakkında Ek Bilgi")
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)

                    Text("Opsiyonel")
                        .font(.caption2.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.cyan)
                        .clipShape(Capsule())

                    Text("İstersen marka, model, renk, ölçü, durum, kutu içeriği, garanti veya kusur gibi bildiklerini yaz; yazmasan da sadece görselle analiz yapılır.")
                        .font(.caption)
                        .foregroundStyle(mutedTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isLightTheme ? Color.white.opacity(0.62) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(cardStrokeColor, lineWidth: 1)
                    )

                if productExtraDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Opsiyonel: Marka/model, renk, ölçü, kullanım durumu, kutu içeriği, garanti, kusur veya alıcının bilmesi gereken detaylar...")
                        .font(.subheadline)
                        .foregroundStyle(mutedTextColor.opacity(0.82))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $productExtraDetails)
                    .font(.subheadline)
                    .foregroundStyle(primaryTextColor)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 116)
                    .background(Color.clear)
            }

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)

                Text("Opsiyoneldir; eklersen AI başlık, açıklama ve risk analizini daha doğru yapar.")
                    .font(.caption)
                    .foregroundStyle(mutedTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    private var privacyNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(mutedTextColor)

            Text("Görsellerin yalnızca analiz için kullanılır.")
                .font(.caption)
                .foregroundStyle(mutedTextColor)
        }
    }

    private var enrichedProductDescription: String {
        var parts: [String] = []

        let baseDescription = productDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !baseDescription.isEmpty {
            parts.append(baseDescription)
        }

        let extraDetails = productExtraDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extraDetails.isEmpty {
            parts.append("Satıcı Ek Bilgisi: \(extraDetails)")
        }

        return parts.joined(separator: "\n")
    }

    private var aiActionButtons: some View {
        EmptyView()
    }

    private var stickyAIActionButton: some View {
        Button {
            navigateToWorkflow = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: 34, height: 34)

                    Image(systemName: "sparkles")
                        .font(.subheadline.bold())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Analizi Başlat")
                        .font(.headline)

                    Text("Tek dokunuşla tüm analizleri oluştur")
                        .font(.caption)
                        .opacity(0.75)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.white, Color(red: 0.92, green: 0.97, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(isLightTheme ? 0.10 : 0.28), radius: 22, x: 0, y: 10)
        }
    }


    private func openCameraSafely() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "Bu cihazda kamera kullanılamıyor. Galeriden görsel seçebilirsin."
            showError = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        errorMessage = "Kamera izni verilmedi. Ayarlardan kamera iznini açabilir veya galeriden görsel seçebilirsin."
                        showError = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Kamera izni kapalı. Ayarlardan kamera iznini açabilir veya galeriden görsel seçebilirsin."
            showError = true
        @unknown default:
            errorMessage = "Kamera şu anda açılamıyor. Galeriden görsel seçebilirsin."
            showError = true
        }
    }

    private var hasAIDraft: Bool {
        !productTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !productDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage.optimizedForAIUpload(maxDimension: 1400)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private extension UIImage {
    func optimizedForAIUpload(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxDimension > 0 else { return fixedOrientation() }

        let scale = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            fixedOrientation().draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    NavigationStack {
        ProductInputView()
    }
}
    
