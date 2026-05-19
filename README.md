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

Canlıya Alınma Durumu: PackWise AI, MVP aşamasını başarıyla geçerek Apple App Store standartlarında production ortamına hazır hale getirilmiştir. 17 Mayıs itibarıyla mağazaya iletilmiş olup, şu anda App Store'da "Waiting for Review" (İnceleme Bekliyor) aşamasındadır. Uygulamanın tüm canlı akışı demo videosunda detaylıca sunulmuştur. Uygulama canlıya alındıktan sonra canlı ortam detayları ve mağaza indirme linki projenin GitHub README kısmına eklenecektir.

---
*Geliştirici:* Yusuf Efe Solak
