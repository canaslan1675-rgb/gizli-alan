package com.offerforge.gizlialan.secondphone

/**
 * Pure (Android-free, JVM unit-tested) rules for "hide work apps while the
 * vault is locked" (issue #30). Runs inside the work profile, where GizliAlan
 * is the profile owner and uses DevicePolicyManager.setApplicationHidden.
 *
 * What gets hidden: every package in the work profile that has a launcher
 * entry (i.e. would show up in the phone launcher's "Work"/"İş" folder or tab)
 * — apps the owner installed from the profile's Play Store, system apps
 * enabled in the profile (Chrome, Files, Contacts…), and the profile's Play
 * Store itself — EXCEPT [NEVER_HIDE] and GizliAlan itself.
 *
 * Why Play Store is hidden too: its icon alone reveals the work profile in the
 * launcher. Hiding does not uninstall anything and does not break restore:
 * unhiding is done by GizliAlan (profile owner) from its own persisted list,
 * which never needs Play Store, and [unhideCandidates] always includes Play
 * Store so it comes back even if that list were lost. "Open Play Store" also
 * unhides it first.
 *
 * Android itself refuses to hide the active admin (us), the package
 * installer/uninstaller/verifier, the permission controller and the default
 * launcher; [NEVER_HIDE] repeats those explicitly and adds Google Play
 * services/framework (other apps and account sign-in depend on them) and
 * OEM security/permission components (Xiaomi/MIUI), so hiding can never make
 * the profile unmanageable.
 */
object HidePolicy {
    const val PLAY_STORE = "com.android.vending"

    val NEVER_HIDE: Set<String> = setOf(
        // Google Play services / services framework: account sign-in, push,
        // licence checks for every other app in the profile.
        "com.google.android.gms",
        "com.google.android.gsf",
        // Install / uninstall / permission UIs (needed to reinstall/manage).
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
        "com.android.permissioncontroller",
        "com.google.android.permissioncontroller",
        // Work-profile provisioning + system settings / UI.
        "com.android.managedprovisioning",
        "com.android.settings",
        "com.android.systemui",
        // Xiaomi / MIUI / HyperOS system components that some ROMs expose
        // with a launcher entry inside the profile.
        "com.miui.securitycenter",
        "com.lbe.security.miui",
        "com.miui.home",
        "com.mi.android.globallauncher",
    )

    /** May [pkg] be hidden? Never ourselves, never an essential package. */
    fun canHide(pkg: String, self: String): Boolean =
        pkg.isNotBlank() && pkg != self && pkg !in NEVER_HIDE

    /**
     * Packages to hide now: launchable ones that are allowed and not already
     * recorded as hidden by us. (Packages hidden by someone else are not
     * launchable, so they are never recorded and never unhidden by us.)
     */
    fun toHide(launchable: Collection<String>, self: String, alreadyHidden: Set<String>): List<String> =
        launchable.asSequence()
            .filter { canHide(it, self) && it !in alreadyHidden }
            .distinct()
            .sorted()
            .toList()

    /** New persisted set after a hide pass: previous set + those that succeeded. */
    fun afterHide(previous: Set<String>, succeeded: Collection<String>): Set<String> =
        previous + succeeded

    /**
     * Packages to unhide on unlock: exactly the ones we recorded, plus Play
     * Store as a safety net (unhiding a visible package is a no-op).
     */
    fun unhideCandidates(recorded: Set<String>): List<String> =
        (recorded + PLAY_STORE).sorted()

    /**
     * New persisted set after an unhide pass: keep only packages whose unhide
     * failed AND that are still installed, so they are retried next time;
     * uninstalled packages are forgotten.
     */
    fun afterUnhide(failed: Collection<String>, stillInstalled: (String) -> Boolean): Set<String> =
        failed.filter(stillInstalled).toSet()
}
