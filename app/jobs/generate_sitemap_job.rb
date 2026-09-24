class GenerateSitemapJob < ApplicationJob
  def perform
    SitemapGenerator::Interpreter.run
  end
end
