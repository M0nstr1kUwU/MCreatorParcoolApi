if (net.minecraft.client.Minecraft.getInstance().options != null) {
    net.minecraft.client.Minecraft.getInstance().options.setCameraType(net.minecraft.client.CameraType.FIRST_PERSON);
    net.minecraft.client.Minecraft.getInstance().options.save();
}