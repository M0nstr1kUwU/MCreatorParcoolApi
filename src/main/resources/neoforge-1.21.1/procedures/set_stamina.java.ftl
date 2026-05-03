net.minecraft.world.entity.player.Player player = (net.minecraft.world.entity.player.Player) ${input$entity};
com.alrex.parcool.api.Stamina s = com.alrex.parcool.api.Stamina.get(player);
int current = s.getValue();
int target = (int) ${input$value};
int delta = target - current;

if (delta > 0) {
    s.recover(delta);
} else if (delta < 0) {
    s.consume(-delta);
}