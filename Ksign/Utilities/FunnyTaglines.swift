//
//  FunnyTaglines.swift
//  Ksign
//
//  Funny random taglines for Settings page
//

import Foundation

struct FunnyTaglines {
	static let taglines: [String] = [
		// Dad Jokes & Puns
		"I'm outstanding in my field... of code!",
		"Why do programmers prefer dark mode? Light attracts bugs!",
		"I told my computer a joke, it returned null.",
		"There's no place like 127.0.0.1",
		"sudo make me a sandwich",
		"404: Motivation not found",
		"I speak fluent sarcasm and Swift",
		"Ctrl+S your progress, not your snacks",
		"Have you tried turning it off and on again?",
		"I debug, therefore I am",
		
		// App Related
		"Now with 100% more pixels!",
		"Batteries not included, neither is patience",
		"Made with love and excessive caffeine",
		"Warning: May cause spontaneous signing",
		"No apps were harmed in the making",
		"Certified organic, locally sourced code",
		"Now in stunning ultra-basic HD!",
		"The app your mom warned you about",
		"Side effects may include productivity",
		"Not responsible for lost sanity",
		
		// Random Fun
		"I put the 'fun' in 'function'",
		"Achievement unlocked: You found me!",
		"Loading personality... please wait",
		"Error 418: I'm a teapot",
		"Powered by hopes, dreams, and Red Bull",
		"This is fine. Everything is fine.",
		"Instructions unclear, signed the fridge",
		"Trust me, I'm an engineer",
		"It works on my machine ¯\\_(ツ)_/¯",
		"Professional overthinker since '95",
		
		// More Nerdy Ones
		"There are 10 types of people in this world...",
		"May the source be with you",
		"Keep calm and clear cache",
		"In a committed relationship with Git",
		"I'm not lazy, I'm on energy saving mode",
		"Roses are red, violets are blue, unexpected '}' on line 32",
		"99 little bugs in the code... take one down...",
		"It's not a bug, it's an undocumented feature",
		"Works 30% of the time, every time",
		"Certified fresh* (*freshness not guaranteed)",
	]
	
	/// Returns a random tagline
	static func random() -> String {
		taglines.randomElement() ?? "Welcome to Ksign!"
	}
	
	/// Returns a tagline based on the current hour (changes throughout the day)
	static func timeBasedTagline() -> String {
		let hour = Calendar.current.component(.hour, from: Date())
		let index = (hour * taglines.count) / 24
		return taglines[index % taglines.count]
	}
}
