<#if input$ENTITY?? && input$WIDTH?? && input$HEIGHT??>
${package}.hitbox.HitboxApiBridge.setTemporaryHitbox(${input$ENTITY}, ${input$WIDTH}, ${input$HEIGHT});
</#if>
