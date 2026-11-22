package com.vinnycream.vinnylock.security

import android.content.Context
import android.util.Base64
import com.vinnycream.vinnylock.core.TextFold
import com.vinnycream.vinnylock.model.CodeKind
import org.json.JSONObject
import java.io.File

/**
 * Nơi giữ mọi bí mật: mã chung, mã riêng từng ứng dụng, câu hỏi và câu trả lời khôi phục.
 * Chỉ lưu bản băm có muối, rồi cả file được mã hóa bằng khóa Keystore.
 * Nằm trong noBackupFilesDir để không bị sao lưu hay khôi phục sang máy khác.
 *
 * Nếu file hỏng hoặc khóa Keystore mất (ví dụ sau khi khôi phục máy), mọi mã coi như
 * chưa đặt. Khi đó phía khóa bỏ qua yếu tố mã thay vì khóa chết người dùng.
 */
class SecretStore(context: Context) {
    private val file = File(context.noBackupFilesDir, "secrets.bin")
    private val lock = Any()
    private var cache: JSONObject? = null

    private fun root(): JSONObject = synchronized(lock) {
        cache ?: load().also { cache = it }
    }

    private fun load(): JSONObject {
        val blob = FileIo.readOrNull(file) ?: return JSONObject()
        return try {
            JSONObject(String(KeystoreCipher.decrypt(blob), Charsets.UTF_8))
        } catch (_: Exception) {
            JSONObject()
        }
    }

    private fun persist(root: JSONObject) {
        FileIo.writeAtomic(file, KeystoreCipher.encrypt(root.toString().toByteArray(Charsets.UTF_8)))
        cache = root
    }

    private fun entry(kind: CodeKind, secret: String): JSONObject {
        val salt = Hasher.newSalt()
        return JSONObject()
            .put("kind", kind.wire)
            .put("salt", b64(salt))
            .put("hash", b64(Hasher.hash(secret, salt)))
    }

    private fun check(entry: JSONObject?, secret: String): Boolean {
        if (entry == null) return false
        val salt = Base64.decode(entry.optString("salt"), Base64.NO_WRAP)
        val hash = Base64.decode(entry.optString("hash"), Base64.NO_WRAP)
        return Hasher.matches(secret, salt, hash)
    }

    private fun b64(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)

    // ---- Mã chung ----

    fun hasMain(): Boolean = root().optJSONObject("main") != null

    fun mainKind(): CodeKind? = root().optJSONObject("main")?.let { CodeKind.parse(it.optString("kind")) }

    fun setMain(kind: CodeKind, secret: String) = synchronized(lock) {
        val r = root()
        r.put("main", entry(kind, secret))
        persist(r)
    }

    fun verifyMain(secret: String): Boolean = check(root().optJSONObject("main"), secret)

    // ---- Mã riêng từng ứng dụng ----

    private fun apps(): JSONObject = root().optJSONObject("apps") ?: JSONObject().also { root().put("apps", it) }

    fun hasApp(pkg: String): Boolean = apps().optJSONObject(pkg) != null

    fun appKind(pkg: String): CodeKind? = apps().optJSONObject(pkg)?.let { CodeKind.parse(it.optString("kind")) }

    fun ownCodePackages(): Set<String> {
        val a = apps()
        return a.keys().asSequence().filter { a.optJSONObject(it) != null }.toSet()
    }

    fun setApp(pkg: String, kind: CodeKind, secret: String) = synchronized(lock) {
        val r = root()
        apps().put(pkg, entry(kind, secret))
        persist(r)
    }

    fun clearApp(pkg: String) = synchronized(lock) {
        val r = root()
        apps().remove(pkg)
        persist(r)
    }

    fun verifyApp(pkg: String, secret: String): Boolean = check(apps().optJSONObject(pkg), secret)

    // ---- Khôi phục ----

    fun hasRecovery(): Boolean = root().optJSONObject("recovery") != null

    fun recoveryQuestion(): String? = root().optJSONObject("recovery")?.optString("question")?.takeIf { it.isNotEmpty() }

    fun setRecovery(question: String, answer: String): Boolean {
        val normalized = TextFold.normalizeAnswer(answer)
        if (question.trim().length < 4 || normalized.length < 2) return false
        synchronized(lock) {
            val r = root()
            r.put("recovery", entry(CodeKind.PIN, normalized).put("question", question.trim()))
            persist(r)
        }
        return true
    }

    fun verifyRecovery(answer: String): Boolean {
        val normalized = TextFold.normalizeAnswer(answer)
        if (normalized.isEmpty()) return false
        return check(root().optJSONObject("recovery"), normalized)
    }
}
