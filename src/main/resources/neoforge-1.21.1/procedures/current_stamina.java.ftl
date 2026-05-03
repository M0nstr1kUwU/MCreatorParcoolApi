(${input$entity} instanceof net.minecraft.world.entity.player.Player
 ? com.alrex.parcool.api.Stamina.get((net.minecraft.world.entity.player.Player) ${input$entity}).getValue()
 : 0)