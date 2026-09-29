package com.sazarcode.enfo.widgets

import org.json.JSONObject

/** A Pomodoro or timer, as the app last described it. */
class Countdown(val json: JSONObject) {
    enum class State { IDLE, RUNNING, PAUSED, DONE }

    val rest: Boolean = json.optBoolean("rest", false)
    val totalSeconds: Int = json.optInt("total", 0)
    private val phase: String = json.optString("phase", "idle")
    private val remainingMs: Long = json.optLong("remainingMs", 0)
    val endsAt: Long? = if (json.has("endsAt")) json.optLong("endsAt") else null

    fun state(now: Long): State = when (phase) {
        "running" -> if (endsAt != null && endsAt <= now) State.DONE else State.RUNNING
        "paused" -> State.PAUSED
        else -> State.IDLE
    }

    /** Time left, for the states that stand still (idle / paused / done). */
    fun stillMs(now: Long): Long = when (state(now)) {
        State.DONE -> 0L
        State.RUNNING -> maxOf(0L, (endsAt ?: now) - now)
        else -> remainingMs
    }

    companion object {
        fun of(snap: Snap?, key: String): Countdown? = snap?.obj(key)?.let { Countdown(it) }
    }
}
