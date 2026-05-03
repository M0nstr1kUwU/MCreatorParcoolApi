if (${input$entity} instanceof net.minecraft.world.entity.player.Player player) {
    net.minecraft.world.entity.ai.attributes.AttributeInstance attribute =
        player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY.get());
    if (attribute != null) {
        attribute.setBaseValue((double) ${input$value});
    }
}