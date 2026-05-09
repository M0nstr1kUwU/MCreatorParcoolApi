<#include "mcitems.ftl">
<#if input$item?? && input$weight??>
${package}.weight.ParCoolApiWeightSystem.setItemWeight(${mappedMCItemToItemStackCode(input$item, 1)}, (double) ${input$weight});
</#if>