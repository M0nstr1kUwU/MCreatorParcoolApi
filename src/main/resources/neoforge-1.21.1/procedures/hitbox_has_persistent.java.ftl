<#if input$ENTITY??>
${package}.hitbox.HitboxApiBridge.hasPersistentHitbox(${input$ENTITY})
<#else>
false
</#if>
