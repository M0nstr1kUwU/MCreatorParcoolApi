<#if input$ENTITY?? && input$WIDTH_MULTIPLIER?? && input$HEIGHT_MULTIPLIER??>
${package}.hitbox.HitboxApiBridge.multiplyPersistentHitbox(${input$ENTITY}, ${input$WIDTH_MULTIPLIER}, ${input$HEIGHT_MULTIPLIER});
</#if>
