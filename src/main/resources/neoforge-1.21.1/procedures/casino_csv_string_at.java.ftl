<#if input$CSV?? && input$INDEX?? && input$FALLBACK??>
${package}.economy.EconomyApiCasino.csvStringAt(String.valueOf(${input$CSV}), ${opt.toInt(input$INDEX)}, String.valueOf(${input$FALLBACK}))
<#else>
""
</#if>