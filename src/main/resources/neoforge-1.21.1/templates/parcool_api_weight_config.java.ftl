package ${package}.weight;
import java.io.IOException;import java.nio.charset.StandardCharsets;import java.nio.file.Files;import java.nio.file.Path;import net.neoforged.fml.loading.FMLPaths;
public final class ParCoolApiWeightConfig{
 private static final Path CONFIG_PATH=FMLPaths.CONFIGDIR.get().resolve("${modid}-weight-server.toml"); private static Config cached; private ParCoolApiWeightConfig(){}
 public static Config get(){if(cached==null)reload();return cached;} public static void reload(){Config c=new Config(); try{if(!Files.exists(CONFIG_PATH))write(c); for(String raw:Files.readAllLines(CONFIG_PATH,StandardCharsets.UTF_8)){String line=raw.split("#",2)[0].trim(); if(line.isEmpty()||!line.contains("="))continue; String k=line.substring(0,line.indexOf('=')).trim(); String v=line.substring(line.indexOf('=')+1).trim().replace(""",""); switch(k){case "weight_enabled"->c.weightEnabled=Boolean.parseBoolean(v);case "use_default_punishments"->c.useDefaultPunishments=Boolean.parseBoolean(v);case "stage_1_percent"->c.stage1Percent=parseDouble(v,c.stage1Percent);case "stage_2_percent"->c.stage2Percent=parseDouble(v,c.stage2Percent);case "stage_3_percent"->c.stage3Percent=parseDouble(v,c.stage3Percent);case "stage_4_percent"->c.stage4Percent=parseDouble(v,c.stage4Percent);case "stage_1_disable_jump"->c.stage1DisableJump=Boolean.parseBoolean(v);case "stage_2_disable_jump"->c.stage2DisableJump=Boolean.parseBoolean(v);case "stage_3_disable_jump"->c.stage3DisableJump=Boolean.parseBoolean(v);case "stage_4_disable_jump"->c.stage4DisableJump=Boolean.parseBoolean(v);case "stage_4_darkness"->c.stage4Darkness=Boolean.parseBoolean(v);}}}catch(Throwable ignored){} cached=c;}
 public static boolean setWeightEnabled(boolean e){Config c=get();c.weightEnabled=e;return save(c);} public static boolean setUseDefaultPunishments(boolean e){Config c=get();c.useDefaultPunishments=e;return save(c);} public static boolean setPunishmentStage(int s,double p,boolean jump,boolean dark){Config c=get();switch(s){case 1->{c.stage1Percent=p;c.stage1DisableJump=jump;}case 2->{c.stage2Percent=p;c.stage2DisableJump=jump;}case 3->{c.stage3Percent=p;c.stage3DisableJump=jump;}case 4->{c.stage4Percent=p;c.stage4DisableJump=jump;c.stage4Darkness=dark;}default->{return false;}}return save(c);} private static boolean save(Config c){try{write(c);cached=c;return true;}catch(Throwable ignored){return false;}}
 private static void write(Config c)throws IOException{Files.createDirectories(CONFIG_PATH.getParent());String text="""# ${modid} Weight Server Config
weight_enabled=%s
use_default_punishments=%s
stage_1_percent=%.2f
stage_2_percent=%.2f
stage_3_percent=%.2f
stage_4_percent=%.2f
stage_1_disable_jump=%s
stage_2_disable_jump=%s
stage_3_disable_jump=%s
stage_4_disable_jump=%s
stage_4_darkness=%s
""".formatted(c.weightEnabled,c.useDefaultPunishments,c.stage1Percent,c.stage2Percent,c.stage3Percent,c.stage4Percent,c.stage1DisableJump,c.stage2DisableJump,c.stage3DisableJump,c.stage4DisableJump,c.stage4Darkness);Files.writeString(CONFIG_PATH,text,StandardCharsets.UTF_8);} private static double parseDouble(String v,double f){try{return Double.parseDouble(v);}catch(Throwable ignored){return f;}}
 public static final class Config{public boolean weightEnabled=true;public boolean useDefaultPunishments=true;public double stage1Percent=75,stage2Percent=100,stage3Percent=150,stage4Percent=200;public boolean stage1DisableJump=false,stage2DisableJump=true,stage3DisableJump=true,stage4DisableJump=true,stage4Darkness=true;}
}
