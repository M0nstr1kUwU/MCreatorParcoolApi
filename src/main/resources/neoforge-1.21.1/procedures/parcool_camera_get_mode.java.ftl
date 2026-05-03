(net.minecraft.client.Minecraft.getInstance().options.getCameraType() == net.minecraft.client.CameraType.FIRST_PERSON
    ? 1
    : (net.minecraft.client.Minecraft.getInstance().options.getCameraType() == net.minecraft.client.CameraType.THIRD_PERSON_BACK
        ? 2
        : 3))