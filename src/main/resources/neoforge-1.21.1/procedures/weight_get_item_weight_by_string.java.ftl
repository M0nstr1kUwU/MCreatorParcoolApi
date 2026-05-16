<#if input$ITEM_ID??>
${package}.weight.ParCoolApiWeightSystem.getUnitWeightById(String.valueOf(${input$ITEM_ID}))
<#else>
0
</#if>