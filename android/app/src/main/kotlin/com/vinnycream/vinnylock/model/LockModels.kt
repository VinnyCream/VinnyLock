package com.vinnycream.vinnylock.model

import org.json.JSONObject

/**
 * Mô hình cấu hình phía Android. Cùng lược đồ JSON với lib/data/models/config_codec.dart.
 * Đọc khoan dung: trường thiếu hoặc sai thì dùng mặc định, không bao giờ ném lỗi ra ngoài.
 */

interface Wire {
    val wire: String
}

private fun <T> parseEnum(values: Array<T>, raw: String?, fallback: T): T where T : Enum<T>, T : Wire =
    values.firstOrNull { it.wire == raw } ?: fallback

enum class AuthMode(override val wire: String) : Wire {
    BIOMETRIC_ONLY("biometricOnly"), CODE_ONLY("codeOnly"), BOTH("both"), EITHER("either")
}

enum class AuthOrder(override val wire: String) : Wire {
    CODE_FIRST("codeFirst"), BIOMETRIC_FIRST("biometricFirst")
}

enum class RelockKind(override val wire: String) : Wire {
    IMMEDIATE("immediate"), SCREEN_OFF("screenOff"), AFTER_SECONDS("afterSeconds")
}

enum class PenaltyKind(override val wire: String) : Wire {
    FIXED("fixed"), ESCALATING("escalating")
}

enum class PenaltyPreset(override val wire: String, val steps: IntArray) : Wire {
    GENTLE("gentle", intArrayOf(30, 60, 120, 300, 600)),
    STANDARD("standard", intArrayOf(30, 60, 300, 900, 3600)),
    STRICT("strict", intArrayOf(60, 300, 900, 3600, 21600))
}

enum class AttemptScope(override val wire: String) : Wire {
    APP("app"), ALL("all")
}

enum class IconMode(override val wire: String) : Wire {
    NORMAL("normal"), DISGUISE("disguise"), HIDDEN("hidden")
}

enum class DisguiseIcon(override val wire: String) : Wire {
    CALCULATOR("calculator"), NOTES("notes"), WEATHER("weather")
}

enum class CodeKind(override val wire: String) : Wire {
    PIN("pin"), PATTERN("pattern");

    companion object {
        fun parse(raw: String?): CodeKind = parseEnum(CodeKind.entries.toTypedArray(), raw, PIN)
    }
}

data class RelockRule(val kind: RelockKind, val seconds: Int = 60) {
    companion object {
        val IMMEDIATE = RelockRule(RelockKind.IMMEDIATE)
    }
}

data class AppPolicy(
    val pkg: String,
    val enabled: Boolean,
    val mode: AuthMode?,
    val order: AuthOrder?,
    val relock: RelockRule?,
    val allowRecovery: Boolean,
)

data class EffectivePolicy(
    val mode: AuthMode,
    val order: AuthOrder,
    val relock: RelockRule,
    val allowRecovery: Boolean,
)

data class DefaultPolicy(val mode: AuthMode, val order: AuthOrder, val relock: RelockRule)

data class AttemptPolicy(
    val threshold: Int,
    val penaltyKind: PenaltyKind,
    val fixedSeconds: Int,
    val preset: PenaltyPreset,
    val scope: AttemptScope,
    val resetAfterHours: Int,
)

data class RecoveryPolicy(val threshold: Int, val preset: PenaltyPreset)

data class LockScreenOptions(
    val hidePattern: Boolean,
    val shuffleKeypad: Boolean,
    val vibrate: Boolean,
    val showAppName: Boolean,
)

data class IconSettings(val mode: IconMode, val disguise: DisguiseIcon)

data class LockConfig(
    val onboardingDone: Boolean,
    val language: String,
    val allowWeakBiometric: Boolean,
    val defaults: DefaultPolicy,
    val attempts: AttemptPolicy,
    val recovery: RecoveryPolicy,
    val lockScreen: LockScreenOptions,
    val icon: IconSettings,
    val apps: Map<String, AppPolicy>,
) {
    fun isLocked(pkg: String): Boolean = apps[pkg]?.enabled == true

    fun effectiveFor(pkg: String): EffectivePolicy {
        val own = apps[pkg]
        return EffectivePolicy(
            mode = own?.mode ?: defaults.mode,
            order = own?.order ?: defaults.order,
            relock = own?.relock ?: defaults.relock,
            allowRecovery = own?.allowRecovery ?: true,
        )
    }

    companion object {
        const val MIN_THRESHOLD = 5
        const val MAX_THRESHOLD = 20

        val INITIAL = LockConfig(
            onboardingDone = false,
            language = "system",
            allowWeakBiometric = true,
            defaults = DefaultPolicy(AuthMode.CODE_ONLY, AuthOrder.CODE_FIRST, RelockRule.IMMEDIATE),
            attempts = AttemptPolicy(
                MIN_THRESHOLD, PenaltyKind.ESCALATING, 60, PenaltyPreset.STANDARD, AttemptScope.APP, 24,
            ),
            recovery = RecoveryPolicy(MIN_THRESHOLD, PenaltyPreset.STANDARD),
            lockScreen = LockScreenOptions(
                hidePattern = false, shuffleKeypad = false, vibrate = true, showAppName = true,
            ),
            icon = IconSettings(IconMode.NORMAL, DisguiseIcon.CALCULATOR),
            apps = emptyMap(),
        )
    }
}

object ConfigJson {
    fun parse(raw: String?): LockConfig {
        if (raw.isNullOrEmpty()) return LockConfig.INITIAL
        return try {
            fromJson(JSONObject(raw))
        } catch (_: Exception) {
            LockConfig.INITIAL
        }
    }

    private fun clampThreshold(v: Int) = v.coerceIn(LockConfig.MIN_THRESHOLD, LockConfig.MAX_THRESHOLD)

    private fun JSONObject.str(key: String): String? =
        if (has(key) && !isNull(key)) optString(key) else null

    private fun JSONObject.obj(key: String): JSONObject = optJSONObject(key) ?: JSONObject()

    private fun relock(o: JSONObject?, fallback: RelockRule): RelockRule {
        if (o == null || o.length() == 0) return fallback
        val kind = parseEnum(RelockKind.entries.toTypedArray(), o.str("kind"), RelockKind.IMMEDIATE)
        return RelockRule(kind, o.optInt("seconds", 60).coerceAtLeast(1))
    }

    private fun fromJson(m: JSONObject): LockConfig {
        val base = LockConfig.INITIAL
        val d = m.obj("defaults")
        val a = m.obj("attempts")
        val r = m.obj("recovery")
        val s = m.obj("lockScreen")
        val i = m.obj("icon")
        val appsObj = m.obj("apps")

        val apps = HashMap<String, AppPolicy>()
        for (pkg in appsObj.keys()) {
            val o = appsObj.optJSONObject(pkg) ?: continue
            val modeRaw = o.str("mode")
            val orderRaw = o.str("order")
            apps[pkg] = AppPolicy(
                pkg = pkg,
                enabled = o.optBoolean("enabled", false),
                mode = modeRaw?.let { parseEnum(AuthMode.entries.toTypedArray(), it, AuthMode.CODE_ONLY) },
                order = orderRaw?.let { parseEnum(AuthOrder.entries.toTypedArray(), it, AuthOrder.CODE_FIRST) },
                relock = o.optJSONObject("relock")?.let { relock(it, RelockRule.IMMEDIATE) },
                allowRecovery = o.optBoolean("allowRecovery", true),
            )
        }

        return LockConfig(
            onboardingDone = m.optBoolean("onboardingDone", false),
            language = m.str("language") ?: base.language,
            allowWeakBiometric = m.optBoolean("allowWeakBiometric", base.allowWeakBiometric),
            defaults = DefaultPolicy(
                mode = parseEnum(AuthMode.entries.toTypedArray(), d.str("mode"), base.defaults.mode),
                order = parseEnum(AuthOrder.entries.toTypedArray(), d.str("order"), base.defaults.order),
                relock = relock(d.optJSONObject("relock"), base.defaults.relock),
            ),
            attempts = AttemptPolicy(
                threshold = clampThreshold(a.optInt("threshold", base.attempts.threshold)),
                penaltyKind = parseEnum(PenaltyKind.entries.toTypedArray(), a.str("penaltyKind"), base.attempts.penaltyKind),
                fixedSeconds = a.optInt("fixedSeconds", base.attempts.fixedSeconds).coerceAtLeast(1),
                preset = parseEnum(PenaltyPreset.entries.toTypedArray(), a.str("preset"), base.attempts.preset),
                scope = parseEnum(AttemptScope.entries.toTypedArray(), a.str("scope"), base.attempts.scope),
                resetAfterHours = a.optInt("resetAfterHours", base.attempts.resetAfterHours).coerceAtLeast(1),
            ),
            recovery = RecoveryPolicy(
                threshold = clampThreshold(r.optInt("threshold", base.recovery.threshold)),
                preset = parseEnum(PenaltyPreset.entries.toTypedArray(), r.str("preset"), base.recovery.preset),
            ),
            lockScreen = LockScreenOptions(
                hidePattern = s.optBoolean("hidePattern", base.lockScreen.hidePattern),
                shuffleKeypad = s.optBoolean("shuffleKeypad", base.lockScreen.shuffleKeypad),
                vibrate = s.optBoolean("vibrate", base.lockScreen.vibrate),
                showAppName = s.optBoolean("showAppName", base.lockScreen.showAppName),
            ),
            icon = IconSettings(
                mode = parseEnum(IconMode.entries.toTypedArray(), i.str("mode"), base.icon.mode),
                disguise = parseEnum(DisguiseIcon.entries.toTypedArray(), i.str("disguise"), base.icon.disguise),
            ),
            apps = apps,
        )
    }
}
