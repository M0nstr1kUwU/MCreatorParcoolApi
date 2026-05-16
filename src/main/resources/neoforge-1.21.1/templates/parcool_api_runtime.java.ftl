package ${package}.parcool;

public final class ParCoolApiRuntime {
	public static final String TARGET_PARCOOL_VERSION = "1.21.1-3.4.3.3-NF";
	public static final String TARGET_CURSEMAVEN_DEPENDENCY = "curse.maven:parcool-482378:7760593";

	private ParCoolApiRuntime() {
	}

	public static boolean isNewLimitationApiAvailable() {
		return isClassAvailable("com.alrex.parcool.api.unstable.Limitation")
			&& isClassAvailable("com.alrex.parcool.api.unstable.Limitation$ID");
	}

	public static boolean isStaminaApiAvailable() {
		return isClassAvailable("com.alrex.parcool.api.Stamina");
	}

	public static boolean isClientInformationPayloadAvailable() {
		return isClassAvailable("com.alrex.parcool.common.network.payload.ClientInformationPayload")
			&& isClassAvailable("com.alrex.parcool.common.info.ClientSetting");
	}

	public static boolean isExpectedRuntimeAvailable() {
		return isNewLimitationApiAvailable()
			&& isStaminaApiAvailable()
			&& isClientInformationPayloadAvailable();
	}

	public static void warnIfRuntimeLooksWrong() {
		if (isExpectedRuntimeAvailable()) {
			return;
		}

		System.err.println("[ParCool API Bridge] Expected ParCool runtime was not detected.");
		System.err.println("[ParCool API Bridge] Target version: " + TARGET_PARCOOL_VERSION);
		System.err.println("[ParCool API Bridge] Target dependency: " + TARGET_CURSEMAVEN_DEPENDENCY);
		System.err.println("[ParCool API Bridge] Make sure the workspace loads ParCool 1.21.1-3.4.3.3-NF, not 3.3.0.0.");
	}

	private static boolean isClassAvailable(String className) {
		try {
			Class.forName(className);
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}
}