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

    /**
     * Hidden on lock even if they have no launcher entry: the profile's
     * system file browser (DocumentsUI). Its cross-profile "Work" tab is how
     * the personal side browses work-profile files (Play downloads, app
     * files); with it hidden that tab has nothing to open (#45).
     */
    val ALSO_HIDE: Set<String> = setOf(
        "com.android.documentsui",
        "com.google.android.documentsui",
    )

    /**
     * User restrictions set on the work profile while the vault is locked and
     * cleared on unlock (#45): no clipboard between profiles, no sharing from
     * the personal side into the profile.
     */
    val LOCK_RESTRICTIONS: List<String> = listOf(
        "no_cross_profile_copy_paste", // UserManager.DISALLOW_CROSS_PROFILE_COPY_PASTE
        "no_sharing_into_profile", // UserManager.DISALLOW_SHARE_INTO_MANAGED_PROFILE
    )

    /** What to hide on lock: launchable apps + [ALSO_HIDE] that are installed. */
    fun lockTargets(launchable: Collection<String>, installed: (String) -> Boolean): Set<String> =
        launchable.toSet() + ALSO_HIDE.filter(installed)

    /** May [pkg] be hidden? Never ourselves, never an essential package. */
    fun canHide(pkg: String, self: String): Boolean =
        pkg.isNotBlank() && pkg != self && pkg !in NEVER_HIDE

    /**
     * Packages to hide now: every launchable package that may be hidden.
     * A package that is launchable is by definition visible, so it is hidden
     * again even if it is already in our recorded set (e.g. Play re-installed
     * or updated it, or it was unhidden outside GizliAlan) — issue #45: the
     * old version skipped recorded packages, so such apps stayed visible in
     * the launcher's Work tab while the vault was locked.
     */
    fun toHide(launchable: Collection<String>, self: String): List<String> =
        launchable.asSequence()
            .filter { canHide(it, self) }
            .distinct()
            .sorted()
            .toList()

    /**
     * Fallback for packages whose hide failed: suspend them instead (icon
     * greyed out and not openable) so they are at least unusable; only
     * hideable packages, never already-suspended-by-us ones.
     */
    fun toSuspend(failedHide: Collection<String>, self: String, alreadySuspended: Set<String>): List<String> =
        failedHide.asSequence()
            .filter { canHide(it, self) && it !in alreadySuspended }
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
