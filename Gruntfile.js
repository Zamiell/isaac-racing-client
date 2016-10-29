module.exports = function(grunt) {

	// Project configuration
	grunt.initConfig({
		concat: {
			dist: {
				src: [
					'app/assets/js/src/main.js',
					'app/assets/js/src/misc.js',
				],
				dest: 'app/assets/js/build/main.js',
			},
		},
		watch: {
			files: ['**/*.js'],
			tasks: ['concat'],
			options: {
				spawn: false,
			},
		},
	});

	// Load plugins
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-watch');

	// Default task(s)
	grunt.registerTask('default', ['concat']);

};
