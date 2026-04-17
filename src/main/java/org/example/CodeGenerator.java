package org.example;

import com.baomidou.mybatisplus.generator.FastAutoGenerator;
import com.baomidou.mybatisplus.generator.engine.FreemarkerTemplateEngine;

public class CodeGenerator {
    public static void main(String[] args) {
        FastAutoGenerator.create("jdbc:postgresql://192.168.234.115:55432/unify-meet", "postgres", "Rhzt0322")
                .globalConfig(builder -> builder
                        .author("hxh")
                        .outputDir(System.getProperty("user.dir") + "/src/main/java")
                        .enableSwagger()
                        .disableOpenDir()
                )
                .packageConfig(builder -> builder
                        .parent("com.rhzt.modules.meet")
                        .controller("controller")
                        .entity("model.entity")
                        .mapper("mapper")
                        .service("service")
                        .xml("mapper.xml")
                )
                .strategyConfig(builder -> builder
                        // 表名
                        .addInclude("meet_attendance_log")
                        .entityBuilder()
                        .enableLombok()
                        .enableFileOverride() // 实体类覆盖
                        .mapperBuilder()
                        .enableFileOverride() // Mapper 覆盖
                        .serviceBuilder() // 新增Service策略配置
                        .formatServiceFileName("%sService") // 生成接口名如PermissionService
                        .enableFileOverride()
                        .enableFileOverride() // Service 覆盖
                        .controllerBuilder()
                        .enableRestStyle()
                        .enableFileOverride() // Controller 覆盖
                )
                .templateEngine(new FreemarkerTemplateEngine())
                // 指定自定义实体模板路径
                .templateConfig(tc -> tc.entity("/templates/entity.java"))
                .execute();
    }
}