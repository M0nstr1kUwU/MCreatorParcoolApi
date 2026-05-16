<#if input$ENTITY??>
(${input$ENTITY} != null ? ${package}.hitbox.HitboxApiBridge.getHeight(${input$ENTITY}) : 0)
<#else>
0
</#if>