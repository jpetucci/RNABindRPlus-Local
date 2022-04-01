singularity run --bind $PWD/tomcat_logs/:/usr/local/tomcat/logs,$PWD/tomcat_work:/usr/local/tomcat/work,$PWD/tomcat_conf_runtime:/usr/local/tomcat/conf/Catalina,$PWD/rnabindrplus:/opt/data,$PWD/webapps:/usr/local/tomcat/webapps rnabindrplus-local.sif

