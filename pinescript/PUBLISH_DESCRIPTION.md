# TradingView Publication — FVG Pro Detector (FxBax.com)

**Script title (exact):** `FVG Pro Detector (FxBax.com)`
**Source file:** `FVG_Pro_Detector.pine` (Pine Script v6, open-source)

---

## Description (paste into TradingView publish form)

**FVG Pro Detector (FxBax.com)** is a complete, all-in-one Fair Value Gap (FVG) indicator based on the classic 3-candle imbalance concept (ICT / Smart Money methodology). It does not just draw gaps — it manages the full lifecycle of every FVG: detection, extension, mitigation, full-fill, and inversion into an Inverse FVG (IFVG).

**How detection works**
A bullish FVG forms when the low of the current candle is higher than the high of the candle two bars earlier (low > high[2]) — a 3-candle displacement gap. The zone is drawn between high[2] and low. A bearish FVG is the mirror case (high < low[2]), drawn between high and low[2]. Zones are created only on confirmed bars, so they never flicker or repaint in real time.

**Features**
- Bullish & bearish FVG detection with automatic zone boxes
- Minimum gap-size filter in three modes: Percent of price, Ticks, or None
- Displacement filter: optionally require a strong middle candle (min body/range)
- Optional "3 aligned candles" mode (the logic of classic basic FVG scripts)
- Session filter: detect gaps only inside your chosen trading window
- Auto-extending zones until mitigated (or fixed bar length)
- CE line — the 50% midline of each zone (Consequent Encroachment), shown as a dashed line
- Mitigation tracking with 3 styles: wick touch, candle close into the zone, or CE (50%) touch
- Full-fill detection: zone fully swept by wicks
- Inverse FVG (IFVG): when price closes completely through a zone, the zone automatically flips polarity and is re-tracked as support/resistance in the opposite direction (orange)
- Mitigated zones are faded (or removed, your choice) and stop extending
- Live statistics table: bullish/bearish count, active zones, mitigated, fully filled, IFVG count
- Built-in alerts: new bullish FVG, new bearish FVG, FVG mitigated, Inverse FVG created

**How to trade with it**
Unmitigated bullish FVGs act as demand zones — traders look for long entries when price returns into them. Bearish FVGs act as supply zones for shorts. The CE (50%) level is often the high-probability reaction point inside a zone. A fully filled gap usually loses its relevance, while a zone broken by a candle body becomes an IFVG and flips its role — a bullish FVG closed below becomes resistance, and vice versa. Combine FVG confluence with structure, liquidity sweeps, and HTF bias.

**Settings**
*Detection:* FVG Threshold (%), Threshold Mode (Percent / Ticks / None), Threshold (Ticks), Require 3 Aligned Candles, Displacement: Min Middle Body, Filter by Session + Session.
*Display:* colors for bullish / bearish / mitigated / IFVG zones, Show CE midline, Show detection arrows, Show zone label (size in ticks), Max active zones, Show stats table.
*Extension:* extend zones until mitigated or for a fixed number of bars.
*Mitigation & Inversion:* Track Mitigation, Mitigation Style (wick touch / close into zone / CE), Convert broken FVG to Inverse FVG, Remove zone when fully filled, Keep mitigated zones faded.

**Alerts**
Open the alert menu and choose one of the built-in conditions: "Bullish FVG detected", "Bearish FVG detected", "FVG mitigated", "Inverse FVG created".

FVGs are areas of interest, not guarantees. Always manage risk and never trade a single signal in isolation.

---

## Release notes (first release)

Initial release: full FVG lifecycle engine — detection with size/displacement/session filters, auto-extending zones, CE midlines, mitigation tracking (touch/close/CE), full-fill detection, automatic Inverse FVG conversion, statistics table, and four built-in alerts.

---

## توضیحات فارسی (برای انتشار در کانال/سایت FxBax)

**FVG Pro Detector (FxBax.com)** یک اندیکاتور کامل برای تشخیص و مدیریت نواحی گپ ارزش منصفانه (FVG) بر اساس سبک ICT / پول هوشمند است. این ابزار فقط گپ‌ها را رسم نمی‌کند، بلکه چرخه کامل هر ناحیه را مدیریت می‌کند: تشخیص، تمدید، میتیگیشن، پر شدن کامل و معکوس شدن به IFVG.

**نحوه تشخیص:** گپ صعودی زمانی شکل می‌گیرد که کف کندل فعلی بالاتر از سقف کندل دو مرحله قبل باشد (low > high[2]) و گپ نزولی برعکس. نواحی فقط روی کندل تأییدشده ساخته می‌شوند؛ بنابراین در لایو چشمک نمی‌زنند و ریپینت ندارند.

**امکانات کلیدی:**
- فیلتر حداقل اندازه گپ به درصد، تیک یا بدون فیلتر
- فیلتر قدرت کندل وسط (Displacement) و فیلتر سشن معاملاتی
- تمدید خودکار ناحیه تا لحظه میتیگیشن + خط میانه ۵۰٪ (CE)
- ثبت میتیگیشن با سه روش: برخورد شدو، کلوز داخل ناحیه، لمس خط میانه
- تشخیص پر شدن کامل گپ و معکوس‌شدگی خودکار به IFVG بعد از شکست با بدنه
- جدول آمار زنده + چهار هشدار آماده (گپ صعودی، گپ نزولی، میتیگیشن، تشکیل IFVG)

**کاربرد معاملاتی:** گپ‌های صعودی میتیگیت‌نشده ناحیه تقاضا و گپ‌های نزولی ناحیه عرضه هستند؛ خط میانه (CE) معمولاً نقطه واکنش با احتمال بالاتر است. گپی که با بدنه کندل شکسته شود به IFVG تبدیل شده و نقش آن برعکس می‌شود. همیشه با ساختار بازار، جمع‌آوری نقدینگی و جهت تایم‌فریم بالا ترکیب شود.
