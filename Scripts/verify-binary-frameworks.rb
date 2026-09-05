#!/usr/bin/env ruby

root = File.expand_path("..", __dir__)
project_file = File.join(root, "Game2D.xcodeproj", "project.pbxproj")
framework_names = %w[TicTacToeEngine SnakeEngine DropMergeEngine]
project_contents = File.read(project_file)

framework_names.each do |name|
  framework_path = File.join(root, "BinaryFrameworks", "#{name}.xcframework")
  abort "Missing binary framework: #{framework_path}" unless File.directory?(framework_path)
  abort "#{name}.xcframework is not linked by Game2D.xcodeproj" unless project_contents.include?("#{name}.xcframework in Frameworks")
  abort "#{name}.xcframework is not embedded by Game2D.xcodeproj" unless project_contents.include?("#{name}.xcframework in Embed Frameworks")
end

puts "All private game XCFrameworks are linked and embedded."
