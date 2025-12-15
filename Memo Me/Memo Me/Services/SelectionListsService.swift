//
//  SelectionListsService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation

class SelectionListsService {
    static let shared = SelectionListsService()
    
    private init() {}
    
    var countries: [String] {
        let unsortedCountries = [
            "中国", "भारत", "United States", "Indonesia", "پاکستان",
            "Brasil", "বাংলাদেশ", "Nigeria", "Россия", "México",
            "日本", "Pilipinas", "ኢትዮጵያ", "مصر", "Việt Nam", "ایران", "Türkiye", "Deutschland", "ประเทศไทย",
            "United Kingdom", "France", "Italia", "Tanzania", "South Africa",
            "မြန်မာ", "Kenya", "대한민국", "Colombia", "España",
            "Uganda", "Argentina", "الجزائر", "السودان", "Україна",
            "العراق", "افغانستان", "Polska", "Canada", "المغرب",
            "السعودية", "Oʻzbekiston", "Perú", "Angola", "Malaysia",
            "Moçambique", "Ghana", "اليمن", "नेपाल", "Venezuela",
            "Madagasikara", "Cameroun", "Côte d'Ivoire", "조선민주주의인민공화국", "Australia"
        ]
        return unsortedCountries.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    var expertiseAreas: [String] {
        let areas = [
            "iOS Development",
            "Android Development",
            "Web Development",
            "Backend Development",
            "Frontend Development",
            "Full Stack Development",
            "UI/UX Design",
            "Graphic Design",
            "Product Design",
            "Machine Learning",
            "Data Science",
            "Artificial Intelligence",
            "DevOps",
            "Cloud Computing",
            "Cybersecurity",
            "Game Development",
            "QA/Testing",
            "Project Management",
            "Business Analysis",
            "Mobile Development",
            "Database Administration",
            "Software Architecture",
            "System Administration",
            "Network Engineering",
            "Embedded Systems",
            "Blockchain",
            "AR/VR Development",
            "Desktop Development",
            "Digital Marketing",
            "Content Creation",
            "Social Media Management",
            "Video Production",
            "Photography",
            "Writing & Editing",
            "Translation",
            "Finance & Accounting",
            "Human Resources",
            "Legal",
            "Consulting",
            "Education",
            "Research",
            "Healthcare",
            "Engineering",
            "Architecture",
            "Sales",
            "Customer Service",
            "Operations",
            "Logistics",
            "Supply Chain",
            "Quality Assurance",
            "Automation",
            "Robotics",
            "Internet of Things (IoT)",
            "Big Data",
            "Business Intelligence",
            "Analytics",
            "E-commerce",
            "Product Management",
            "Agile/Scrum",
            "API Development",
            "Microservices",
            "Serverless"
        ]
        return areas.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    var notInListCountry: String {
        "Not yet in the list"
    }
}
