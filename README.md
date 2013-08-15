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

* O relatório é apresentado através do método __index__ do __/app/controllers/reports_controller.rb__. Ele não fáz absolutamente nada, à não ser retornar para a view, presente no arquivo __/app/views/reports/index.html.erb__.

* Dentro do arquivo __/app/views/reports/index.html.erb__ temos toda a lógica para abertura do relatório e sua apresentação através do Crystal Reports Viewer. O seu conteúdo é:

	```ruby
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

* Logo na primeira linha, definimos qual o relatório será aberto, informando o caminho relativo do relatório. Esse caminho levará em consideração o caminho definido no arquivo __/lib/CRConfig.xml__. Neste projeto, o caminho está definido para a raiz da aplicação. Logo, nesse caso, o relatório será procurado na pasta __/rpts__ presente na raiz da aplicação.

* Outro ponto que devemos prestar atenção é na última linha. O método __processHttpRequest()__ da class __CrystalReportViewer__ espera como parâmetros o servlet request, o servlet response e o sevlet context da aplicação. Segundo a documentação do [jruby-rack](https://github.com/jruby/jruby-rack), a referência para o servlet context da aplicação é passado para o Rack como uma variável de ambiente acessível através da variável global __$servlet_context__, enquanto as referências para servet request e o servlet response, são obtidos respenctivamente através das variáveis de ambiente __java.servlet_request__ e __java.servlet_response__. Criei então métodos no __/app/controllers/application_controller.rb__ para retornar a referência para esses objetos e os expus como methods helpers, conforme código abaixo.

	```ruby
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

* 