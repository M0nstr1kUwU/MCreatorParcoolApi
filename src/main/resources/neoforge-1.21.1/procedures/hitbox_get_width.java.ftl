<#if input$ENTITY??>
(${input$ENTITY} != null ? ${package}.hitbox.HitboxApiBridge.getWidth(${input$ENTITY}) : 0)
<#else>
0
</#if>