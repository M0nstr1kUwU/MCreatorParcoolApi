if (net.minecraft.client.Minecraft.getInstance().options != null) {
    net.minecraft.client.Minecraft.getInstance().options.setCameraType(net.minecraft.client.CameraType.THIRD_PERSON_FRONT);
    net.minecraft.client.Minecraft.getInstance().options.save();
}