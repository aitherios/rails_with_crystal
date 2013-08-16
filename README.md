rails_with_crystal
==================

Aplicação de exemplo com a integração entre o Java Crystal Reports Viewer distribuído junto com o [Crystal Reports Version for Eclipse](https://www54.sap.com/solution/sme/software/analytics/crystal-reports-eclipse/index.html).

# Motivação

Quem já foi obrigado a desenvolver relatórios em suas aplicações Rails, sabe o quanto a plataforma Ruby é carente de bibliotecas que forneçam boas soluções. Gems como [PrawnPDF](https://github.com/prawnpdf/prawn) e o [pdfkit](https://github.com/pdfkit/pdfkit), apesar de adequadas para o que se propõem, não são robustas para relatórios mais avançados.

Como consultor de Business Intelligence, estou acostumado a utilizar o SAP Crystal Reports para criar relatórios, e pessoalmente a considero excepcional. Ela é robusta, com uma excelente interface para visual para a criação dos relatórios, e uma curva de aprendizado relativamente suave se comparada a alterantivas Open Source como o Jasper Report e o seu sofrível iReport Designer.

Resolvi então gastar um tempinho e fazer essa integração que descrevo aqui.

# O que foi utilizado nesse projeto?

Utilizei as seguintes ferramentas e bibliotecas, com suas respectivas versões para criar esse projeto.

* Oracle JDK 1.6.0
* JRuby 1.7.0
* Rails 3.2.9
* Trinidad 1.4.5 com Tomcat 7.0.41.
* Warbler 1.3.8
* Crystal Reports Version for Eclipse

A configuração da aplicação envolve, primeiramente o esforço para configurar o ambiente de desenvolvimento, e segundo para configurar a aplicação para ser empacotada e publicada em outros ambientes.

# Uso desse projeto.

O uso desse projeto é bastante simples. Primeiro, clone-o para um repositório local...

	```bash
	$ git clone git@github.com:geekmind/rails_with_crystal.git
	```
	
… instale as dependência…
	
	```bash
	$ bundle install
	```
	
… e inicie aplicação usando o [Trinidad](https://github.com/trinidad/trinidad).

	```bash
	$ trinidad
	```
	
Tente acessar a aplicação pelo endereço http://localhost:3000. Se tudo ocorreu bem, o Crystal Report Viewer deve ser apresentado com um relatório de exemplo.

# Explorando o projeto.

* O relatório é apresentado através do método __index__ do __/app/controllers/reports_controller.rb__. Ele não faz absolutamente nada, à não ser retornar para a view, presente no arquivo __/app/views/reports/index.html.erb__.

* Dentro do arquivo __/app/views/reports/index.html.erb__, é onde se encontra toda a lógica para abertura do relatório e sua apresentação através do Crystal Reports Viewer. O seu conteúdo é:

	```Ruby
	<%
  
		# Defining report file path.
  		report_file_name = "rpts/CrystalReport1.rpt"
  
  		# Open report.
  		report_document = com.crystaldecisions.sdk.occa.report.application.ReportClientDocument.new
  		report_document.open(report_file_name,0)
  
  		# Get report source.
	  	report_source = report_document.getReportSource
  
  		# Create report viewer.
  		report_viewer = com.crystaldecisions.report.web.viewer.CrystalReportViewer.new
  		report_viewer.setReportSource(report_source)
  		report_viewer.setOwnPage(true)

  		# Show report in report viewer.
  		report_viewer.processHttpRequest(servlet_request, servlet_response, servlet_context, nil);
  
	%>
	```

* Logo na primeira linha, defini qual o relatório será aberto, informando o caminho relativo do relatório. Esse caminho levará em consideração o caminho definido no arquivo __/lib/CRConfig.xml__. Neste projeto, o caminho está definido para a raiz da aplicação. Logo, nesse caso, o relatório será procurado na pasta __/rpts__ presente na raiz da aplicação.

* Outro ponto que que vale à pena ressaltar é a última linha. O método __processHttpRequest()__ da class __CrystalReportViewer__ espera como parâmetros o servlet request, o servlet response e o sevlet context da aplicação. Segundo a documentação do [jruby-rack](https://github.com/jruby/jruby-rack), a referência para o servlet context da aplicação é passado para o Rack como uma variável de ambiente acessível através da variável global __$servlet_context__, enquanto as referências para servet request e o servlet response, são obtidos respenctivamente através das variáveis de ambiente __java.servlet_request__ e __java.servlet_response__. Criei então três métodos no __/app/controllers/application_controller.rb__ para retornar a referência para esses objetos e os expus como methods helpers, conforme código abaixo.

	```Ruby
	class ApplicationController < ActionController::Base
  		protect_from_forgery
  		helper_method :servlet_context, :servlet_request, :servlet_response
  
  		# Return servlet context.
  		def servlet_context
    		return $servlet_context
  		end
  
  		# Return servlet request.
  		def servlet_request
    		return request.env['java.servlet_request']
  		end
  
	  	# Return servlet response.
  		def servlet_response
    		return request.env['java.servlet_response']
  		end
  
	end
	```
	
* Os arquivos para o Crystal Report Viewer DHTML estão na pasta __/crystalreportviewers__ na raiz da aplicação. Isso faz com que ele esteja na raiz do __webapp__ quando publicado em um servlet container. Justamente o local esperado por padrão.

* As bibliotecas do Crystal SDK estão na pasta __/lib/java__. Este é o lugar padrão utilizado pelo Trinidad, e o configurei para ser também o local padrão do [Warbler](https://github.com/jruby/warbler), para pesquisar pelas bibliotecas Java (.jars).

* O arquivo __/config/warble.rb__ contém as configurações necessárias para o empacotamento da aplicação. A principal configuração que deve ser precebida é a inclusão da pasta __/crystalreportviewers__ na raiz da aplicação ao ser empacotada.

* Ainda nesse arquivo, incluí a entrada __/lib/java/*.jar__  na configuração __java_libs__, para serem carregados quando a aplicação for empacotada. Ativei também a compatibilidade com o Ruby 1.9, mas sem nenhum motivo especial. Apenas porque eu estou usando essa versão.

* O arquivo __/config/trinidad.rb__ é responsável por configurar o Trinidad para executar em ambiente de desenvolvimento. Nele, defini qual o ambiente (RUBY_ENV) será executado por padrão. Segue o conteúdo do arquivo.

	```Ruby
	Trinidad.configure do |config|
  		config.environment = :development
	end
	```

* Por fim, criei também o arquivo __/config/web.xml__ que é utilizado por padrão, tanto pelo Trinidad quanto pelo Warbler para configurar a aplicação. Precisei cria-lo, para incluir o servlet do Crystal Report Viewer, que deve vir impreterivelmente antes do filtro do jruby-rack, para que não haja conflito de padrões de URL na aplicação. Veja como ficou.

	```xml
	<?xml version="1.0" encoding="UTF-8"?>
<web-app  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
          xmlns="http://java.sun.com/xml/ns/javaee" 
          xmlns:web="http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd"
          xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd"      
          id="WebApp_ID" 
          version="2.5">

          <display-name>Rails With Java Crystal Reports</display-name>

          <!-- Crystal Reports servlet configuration. -->
          <servlet>
            <servlet-name>CrystalReportViewerServlet</servlet-name>
            <servlet-class>com.crystaldecisions.report.web.viewer.CrystalReportViewerServlet</servlet-class>
          </servlet>
          
          <servlet-mapping>
            <servlet-name>CrystalReportViewerServlet</servlet-name>
            <url-pattern>/CrystalReportViewerHandler</url-pattern>
          </servlet-mapping>
          
          <context-param>
            <param-name>crystal_image_uri</param-name>
            <param-value>/crystalreportviewers</param-value>
          </context-param>
          
          <context-param>
            <param-name>crystal_image_use_relative</param-name>
            <param-value>webapp</param-value>
          </context-param>

          <!-- JRuby Rack Filter configuration. -->
          <context-param>
            <param-name>public.root</param-name>
            <param-value>/</param-value>
          </context-param>

          <context-param>
            <param-name>jruby.min.runtimes</param-name>
            <param-value>1</param-value>
          </context-param>
          
          <context-param>
            <param-name>jruby.max.runtimes</param-name>
            <param-value>1</param-value>
          </context-param>

          <filter>
            <filter-name>RackFilter</filter-name>
            <filter-class>org.jruby.rack.RackFilter</filter-class>
          </filter>
          
          <filter-mapping>
            <filter-name>RackFilter</filter-name>
            <url-pattern>/*</url-pattern>
          </filter-mapping>

          <listener>
            <listener-class>org.jruby.rack.rails.RailsServletContextListener</listener-class>
          </listener>
          
	</web-app>
	
	```
	
* Tive problemas de falta de memoria (java.lang.OutOfMemory) que foram resolvidos com o devido ajuste de memória.

	```bash
	$ jruby --server -J-Xmx2048m -J-Xms2048m -J-Xmn512m -J-XX:MaxPermSize=512m -S trinidad --threadsafe
	```
	
* Criei um script na raiz da aplicação chamado __start_trinidad.sh__ para simplificar o uso.


