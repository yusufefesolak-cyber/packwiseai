# PackWise AI 📦🧠
**Akıllı Analiz, Güvenli Teslimat**

PackWise AI, e-ticaret satıcıları için geliştirilmiş **üretken yapay zeka destekli bir akıllı ürün ve risk analiz asistanıdır.** Satıcıların ürün görsellerini alıp; iade riskini düşürmek, kargo hasarlarını önlemek ve pazaryeri algoritmasına uygun ilanlar oluşturmak için uçtan uca bir rapor sunar.

BTK Akademi, Google ve Girişimcilik Vakfı ortaklığında düzenlenen **Hackathon'26** için geliştirilmiştir.

## 🚀 Öne Çıkan Özellikler
* **Görsel Ön Tanıma (Human-in-the-loop):** Gemini Vision ile yüklenen fotoğraf üzerinden ürünün kategorisini, materyalini ve kırılganlık seviyesini anında tanır.
* **Açıklanabilir Risk Skorlaması (Explainable AI):** İade ve hasar riskini (0-100) hesaplar ve YZ'nin bu skoru *neden* verdiğini şeffafça açıklar.
* **Müşteri Yorumu Simülasyonu:** "Bu ürünü bu şekilde gönderirsem müşteri ne der?" sorusunu öngörerek muhtemel olumlu/olumsuz yorumları simüle eder.
* **Akıllı Aksiyon Planı:** Skoru düşürmek için kategoriye özel, somut paketleme ve ilan iyileştirme rehberi sunar.
* **Pazaryeri Hazırlığı:** Ürün görseli ve bilgilerinden SEO uyumlu ilan başlığı ve satış açıklaması üretir.

## 🛠 Kullanılan Teknolojiler
* **Uygulama Geliştirme:** Swift & SwiftUI (Tamamen Native)
* **Yapay Zeka (Ana Motor):** Google Gemini API (`gemini-2.5-flash` ve `gemini-2.0-flash`)
* **Mimari:** Agentic AI Workflow (Visual, Return Risk, Damage ve Listing Agent simülasyonları)

## ⚠️ Jüri Değerlendirmesi İçin API Key Notu
Projeyi derleyip test edebilmeniz için `GeminiService.swift` ve `Info.plist` dosyalarındaki API Key demo amaçlı olarak proje içinde bırakılmış ve kota ile sınırlandırılmıştır. İhtiyaç halinde kendi Gemini API Key'inizi ilgili `apiKey` değişkenine tanımlayarak kullanabilirsiniz.

> 💡 **Önemli Not:** Eğer bot taramalarından dolayı demo API anahtarı kotaya takılırsa, lütfen kendi Gemini API anahtarınızı `GeminiService.swift` içerisindeki ilgili alana tanımlayınız.

## 🚀 Canlıya Alınma Durumu
PackWise AI, MVP aşamasını başarıyla geçerek Apple App Store standartlarında production ortamına hazır hale getirilmiştir. 17 Mayıs itibarıyla mağazaya iletilmiş olup, şu anda App Store'da **"Waiting for Review" (İnceleme Bekliyor)** aşamasındadır. Uygulamanın tüm canlı akışı demo videosunda detaylıca sunulmuştur. Uygulama canlıya alındıktan sonra canlı ortam detayları ve mağaza indirme linki projenin GitHub README kısmına eklenecektir.

# 📱 PackWise AI - Nasıl Kullanılır? (User Guide)

PackWise AI'ı kullanarak e-ticaret ürünlerinizin risk analizini yapmak ve saniyeler içinde akıllı ilanlar oluşturmak için aşağıdaki adımları takip edebilirsiniz.

---

### 🔍 Adım 1: Yeni Bir Analiz Başlatın
Uygulamayı açtığınızda sizi karşılayan modern ana ekranda bulunan **"New Analysis"** (Yeni Analiz) butonuna dokunun. Bu buton sizi kamera ve galeri entegrasyonunun olduğu giriş ekranına yönlendirecektir.

### 📸 Adım 2: Ürün Fotoğrafını Yükleyin
Analiz etmek istediğiniz e-ticaret ürününün:
* İster **Kamera** ikonuna basarak anlık olarak fotoğrafını çekin,
* İster **Galeri** ikonuna basarak mevcut bir ürün görselini sistemimize yükleyin.

### 🧠 Adım 3: Akıllı Raporu İnceleyin
Görsel yüklendiği an Gemini Vision yapay zeka modelimiz devreye girer ve saniyeler içinde şu uçtan uca raporu oluşturur:
* **Hasar & İade Risk Skoru:** Ürününüzün kargoda kırılma veya iade edilme riskini 0-100 arası puanlar.
* **Açıklanabilir Gerekçe (Explainable AI):** Yapay zekanın bu skoru neden verdiğini mantıksal detaylarıyla açıklar (Örn: "Ürün kırılgan seramik materyalden üretilmiştir").
* **Paketleme Rehberi:** Risk skorunu düşürmek için satıcıya somut aksiyon planları sunar (Balonlu naylon kullanımı, kutu içi destek vb.).
* **Müşteri Yorumu Simülasyonu:** Ürünün bu paketlemeyle gönderilmesi halinde gelebilecek olası olumlu ve olumsuz müşteri geri bildirimlerini öngörür.

### 📝 Adım 4: Yapay Zeka İlan Bilgilerini Alın
Aynı ekranda yapay zeka, ürün görselinden yola çıkarak Trendyol, Hepsiburada ve Amazon gibi pazaryeri algoritmalarına uyumlu **SEO odaklı İlan Başlığı** ve **Ürün Açıklaması** üretir. Bu bilgileri kopyalayarak doğrudan mağazanızda kullanabilirsiniz.

### 🕒 Adım 5: Geçmiş Analizleri Takip Edin ve Temayı Değiştirin
* Alt menüde bulunan **History** sekmesinden daha önce yaptığınız tüm analizlerin raporlarına tek tıkla yeniden ulaşabilirsiniz.
* Uygulamayı kendi kullanım alışkanlığınıza göre **Koyu Tema (Dark Mode)** veya **Açık Tema (Light Mode)** olarak deneyimleyebilirsiniz.

### 🖼️ Uygulama İçi Ekran Görüntüleri

| Ana Ekran & Görsel Yükleme | Akıllı Risk Raporu | SEO İlan Üretimi & Geçmiş |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/74546977-6564-4a29-8a10-7b7340b53151" width="280"> | <img src="https://github.com/user-attachments/assets/3089bd3d-e5df-4e41-a7ab-bfac0a055e92" width="280"> | <img src="https://github.com/user-attachments/assets/c2368d11-5f1c-4e28-a1c7-7a97e91dd233" width="280"> |


---

* 📱 **Ürün Tanıtım Video Linki:** [YouTube Shorts İzle](https://www.youtube.com/shorts/hky2DyDe-mc)
* ✉️ **Geliştirici Maili:** yusufefesolak@gmail.com

---
*Geliştirici:* **Yusuf Efe Solak**
