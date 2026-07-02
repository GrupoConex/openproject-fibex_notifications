Gem::Specification.new do |s|
  s.name        = 'openproject-fibex_notifications'
  s.version     = '1.0.0'
  s.authors     = ['Fibex Telecom']
  s.email       = ['soporte@fibextelecom.info']
  s.summary     = 'Fibex Notifications – SMS, WhatsApp & Email delivery via fibex-communications API'
  s.description = 'OpenProject plugin that routes notifications through the fibex-communications microservice, supporting email, WhatsApp (Meta API), and SMS (Tedexis) channels.'
  s.license     = 'GPL-3.0'

  s.files       = Dir['{app,config,db,lib}/**/*'] + %w[README.md init.rb]

  s.add_dependency 'rails', '>= 7.1'
  s.add_dependency 'faraday', '~> 2.0'
  s.add_dependency 'faraday-retry', '~> 2.0'
end
