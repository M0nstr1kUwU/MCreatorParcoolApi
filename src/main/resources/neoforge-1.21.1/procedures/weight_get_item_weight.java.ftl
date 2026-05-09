<#include "mcitems.ftl">
<#if input$item??>
${package}.weight.ParCoolApiWeightSystem.getStackWeight(${mappedMCItemToItemStackCode(input$item, 1)})
<#else>
0
</#if>