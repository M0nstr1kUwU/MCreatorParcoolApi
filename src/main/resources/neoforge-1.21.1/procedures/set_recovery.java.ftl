if (${input$entity} instanceof net.minecraft.world.entity.player.Player) {
    net.minecraft.world.entity.player.Player player = (net.minecraft.world.entity.player.Player) ${input$entity};
    net.minecraft.world.entity.ai.attributes.AttributeInstance attribute = player.getAttribute(com.alrex.parcool.registry.Attributes.MAX_STAMINA);
    if (attribute != null) {
        attribute.setBaseValue(${input$value});
    }
}