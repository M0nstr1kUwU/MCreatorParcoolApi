<#if input$STAGE?? && input$PERCENT?? && input$DISABLE_JUMP?? && input$DARKNESS??>
${package}.weight.ParCoolApiWeightConfig.setPunishmentStage(${opt.toInt(input$STAGE)}, ${input$PERCENT}, ${input$DISABLE_JUMP}, ${input$DARKNESS});
</#if>
