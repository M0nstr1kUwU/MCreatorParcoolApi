<#if input$ITEM_ID?? && input$WEIGHT??>
${package}.weight.ParCoolApiWeightSystem.setItemWeightById(String.valueOf(${input$ITEM_ID}), (double) ${input$WEIGHT});
</#if>