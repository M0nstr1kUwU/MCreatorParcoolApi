<#if input$item_id??>
${package}.weight.ParCoolApiWeightSystem.getUnitWeightById(String.valueOf(${input$item_id}))
<#else>
0
</#if>