# DRAFT — Privacy policy additions for GizliAlan 0.6.2 (Joi)

> **Status: draft, NOT published.** The live policy is served by GitHub Pages
> from `main:/docs/privacy/` — this file changes nothing there. After Demirhan
> approves the wording, merge these sections into `PRIVACY.md` and
> `docs/privacy/index.html` (EN + TR, RU mirrors EN) and bump "Last updated".

## EN — new section "Joi assistant (since 0.6.2)"

Joi is an optional AI assistant inside the vault. It can answer in two ways:

- **On the device** (Gemini Nano via Android AICore, where available): nothing leaves the phone.
- **Online** (only after you accept the one-time Joi online consent): the text
  you type or dictate to Joi, the last few turns of the current Joi chat and,
  for Pro users with "Joi memory" on, the short memory facts relevant to the
  question are sent over an encrypted connection to **Google's Gemini API**
  (via Firebase AI Logic, project operated by the developer). We do not run a
  server and do not store these messages. The developer uses Google's **paid
  tier**; under Google's terms, prompts and answers on the paid tier are **not
  used to train Google's models** ([Gemini API terms](https://ai.google.dev/gemini-api/terms)).
  Google may process the data outside Türkiye.
- **Your notes, photos, files and PIN are never sent online.** "Search / ask
  my notes" and note summaries run only on the device. If you ask Joi to write
  a note, only your request is sent; the resulting note is stored encrypted in
  your vault.

**Free limit.** The free version includes 10 online Joi messages per day. Only
the date and a counter are stored on the device (SharedPreferences) to enforce
this; no message text.

**Voice (Pro).** Speech-to-text uses Android's speech recognizer (Google's
speech service or the on-device recognizer installed on your phone). Depending
on your device, Google's service may process the audio under Google's own
privacy policy. GizliAlan does not record or store audio. Spoken answers use
the Android text-to-speech engine on your phone.

**Chat history and memory (Pro).** Saved Joi chats and "Joi memory" facts are
stored **only on your device, AES-256-GCM encrypted** inside the vault. You can
view and delete memory items (Joi → Memory) and clear the chat at any time;
"Reset everything" or uninstalling removes them.

**Photos from Wikimedia Commons (Pro).** When you ask Joi for a photo, the
search words (e.g. "Galata Tower") are sent to **Wikimedia Commons**
(commons.wikimedia.org, [privacy policy](https://foundation.wikimedia.org/wiki/Policy:Privacy_policy)),
which sees your IP address like any website. Images you save go into your vault
or, if you choose, your Pictures folder.

**App Check / Play Integrity.** To stop abuse of the Joi online service, the
app uses **Firebase App Check with Google Play Integrity**, which sends a
device/app integrity attestation to Google. It contains no vault content.

**Reporting answers.** Each Joi answer has a **Report** button. It opens your
own e-mail app addressed to delibaltabaris5@gmail.com with the reason and the
text of that answer only; you decide whether to send it.

Joi is an AI and can be wrong; do not rely on it for medical, legal or
financial decisions.

## TR — yeni bölüm "6e. Joi asistanı (0.6.2'den)"

Joi, kasanın içindeki isteğe bağlı bir yapay zeka asistanıdır.

- **Cihazda** (destekleyen telefonlarda Android AICore / Gemini Nano): hiçbir veri telefondan çıkmaz.
- **Çevrimiçi** (yalnızca Joi çevrimiçi onayını verdikten sonra): Joi'ye
  yazdığın veya söylediğin metin, mevcut sohbetin son birkaç mesajı ve Pro'da
  "Joi hafızası" açıksa soruyla ilgili kısa hafıza bilgileri şifreli bağlantıyla
  **Google Gemini API**'ye (Firebase AI Logic üzerinden) gönderilir. Kendi
  sunucumuz yoktur, bu mesajları saklamayız. Geliştirici Google'ın **ücretli
  katmanını** kullanır; Google şartlarına göre ücretli katmandaki istek ve
  yanıtlar **Google modellerinin eğitiminde kullanılmaz**. Veriler Google
  tarafından yurt dışında işlenebilir (KVKK md.9; açık rızan çevrimiçi onay
  ekranında alınır).
- **Notların, fotoğrafların, dosyaların ve PIN'in asla çevrimiçi gönderilmez.**
  Notlarda arama ve not özetleri yalnızca cihazda çalışır. Joi'den not
  yazmasını istersen yalnızca isteğin gönderilir; oluşan not kasanda şifreli
  saklanır.

**Ücretsiz sınır.** Ücretsiz sürümde günde 10 çevrimiçi Joi mesajı vardır;
bunun için cihazda yalnızca tarih ve sayaç tutulur, mesaj metni tutulmaz.

**Ses (Pro).** Konuşmayı yazıya çevirmek için telefonundaki Android ses
tanıyıcısı (Google konuşma hizmeti veya cihaz içi tanıyıcı) kullanılır;
cihazına göre ses Google tarafından kendi gizlilik politikasıyla işlenebilir.
GizliAlan ses kaydetmez, saklamaz. Sesli yanıtlar telefonundaki metin okuma
motoruyla üretilir.

**Sohbet geçmişi ve hafıza (Pro).** Kaydedilen Joi sohbetleri ve hafıza
bilgileri **yalnızca cihazında, kasanın içinde AES-256-GCM ile şifreli**
saklanır. Hafıza öğelerini görüp silebilir (Joi → Hafıza), sohbeti her an
temizleyebilirsin.

**Wikimedia Commons fotoğrafları (Pro).** Joi'den fotoğraf istediğinde arama
kelimeleri **Wikimedia Commons**'a (commons.wikimedia.org) gönderilir; site
her web sitesi gibi IP adresini görür.

**App Check / Play Integrity.** Joi çevrimiçi hizmetinin kötüye kullanımını
önlemek için **Firebase App Check ve Google Play Integrity** kullanılır; bu,
Google'a cihaz/uygulama bütünlük doğrulaması gönderir, kasa içeriği içermez.

**Yanıt bildirme.** Her Joi yanıtında **Bildir** düğmesi vardır; kendi e-posta
uygulamanı delibaltabaris5@gmail.com adresine, yalnızca sebep ve o yanıtın
metniyle açar; göndermeye sen karar verirsin.

Joi bir yapay zekadır ve yanılabilir; sağlık, hukuk veya para kararlarında
tek kaynak olarak kullanma.

## Other edits needed when merging
- EN "Summary" / TR "2. Özet": add "Optional Joi online answers send only what you type to Google Gemini (see Joi)."
- "What the app does NOT do": replace "No … microphone … access" with "Microphone only for Joi voice input (Pro), only while you hold/tap the mic."
- Permissions table: add `RECORD_AUDIO` (Joi voice) if declared in the manifest; INTERNET row: add Joi online + Wikimedia Commons.
- TR "8. Aktarım": add Google (Gemini, Play Integrity) and Wikimedia as recipients, abroad.
- "Changes" / "12. Değişiklikler": mention 0.6.2 Joi.
