<#if input$item_id?? && input$weight??>
${package}.weight.ParCoolApiWeightSystem.setItemWeightById(String.valueOf(${input$item_id}), (double) ${input$weight});
</#if>