if (${input$entity} instanceof net.minecraft.world.entity.player.Player) {
    net.minecraft.world.entity.player.Player player = (net.minecraft.world.entity.player.Player) ${input$entity};
    com.alrex.parcool.api.Stamina stamina = com.alrex.parcool.api.Stamina.get(player);
    int current = stamina.getValue();
    int target = (int) ${input$value};
    int delta = target - current;

    if (delta > 0) {
        stamina.recover(delta);
    } else if (delta < 0) {
        stamina.consume(-delta);
    }
}