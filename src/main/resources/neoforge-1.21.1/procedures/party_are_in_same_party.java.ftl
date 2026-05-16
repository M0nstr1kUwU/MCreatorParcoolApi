<#if input$ENTITY?? && input$TARGET??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _partyA && ${input$TARGET} instanceof net.minecraft.server.level.ServerPlayer _partyB) && ${package}.party.PartyApiSystem.areInSameParty(_partyA, _partyB))
<#else>
false
</#if>
