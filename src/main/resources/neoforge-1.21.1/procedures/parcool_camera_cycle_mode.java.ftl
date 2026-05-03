if (net.minecraft.client.Minecraft.getInstance().options != null) {
    net.minecraft.client.Minecraft.getInstance().options.setCameraType(
        net.minecraft.client.Minecraft.getInstance().options.getCameraType().cycle()
    );
    net.minecraft.client.Minecraft.getInstance().options.save();
}