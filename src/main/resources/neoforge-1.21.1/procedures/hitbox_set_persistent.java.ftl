<#if input$ENTITY?? && input$WIDTH?? && input$HEIGHT??>
${package}.hitbox.HitboxApiBridge.setPersistentHitbox(${input$ENTITY}, ${input$WIDTH}, ${input$HEIGHT});
</#if>
