<#if input$CSV?? && input$INDEX?? && input$FALLBACK??>
${package}.economy.EconomyApiCasino.csvDoubleAt(String.valueOf(${input$CSV}), ${opt.toInt(input$INDEX)}, ${input$FALLBACK})
<#else>
0
</#if>