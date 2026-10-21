export const profile = {
  name: 'Lê Văn Khiêm',
  role: 'DevOps Intern',
  location: 'Hanoi, Vietnam',
  email: 'levankhiem0000@gmail.com',
  phone: '0338882562',
  github: 'https://github.com/khimkhum',
  resume: '/cv/le-van-khiem-devops.pdf',
  objective:
    'Information Technology student at the Academy of Cryptography Techniques, seeking a DevOps internship. I learn by building, troubleshooting, and documenting hands-on projects across cloud infrastructure, deployment automation, and system operations.',
  education: {
    degree: 'Information Technology',
    school: 'Academy of Cryptography Techniques',
    originalName: 'Học viện Kỹ thuật Mật mã · KMA',
    years: '2022 — 2027',
  },
};

export const skills = [
  { name: 'Systems & scripting', tools: ['Linux', 'Bash', 'Python'] },
  { name: 'Containers & orchestration', tools: ['Docker', 'Docker Compose', 'Kubernetes', 'k3d', 'Helm'] },
  { name: 'Cloud & infrastructure', tools: ['AWS', 'Terraform'] },
  { name: 'Delivery & GitOps', tools: ['Git', 'GitHub', 'GitHub Actions', 'Argo CD'] },
  { name: 'Data & registry', tools: ['Harbor', 'PostgreSQL'] },
  { name: 'Observability', tools: ['Prometheus', 'Grafana'] },
];

export const projects = [
  {
    id: '01',
    title: 'VProfile',
    category: 'Cloud infrastructure & CI/CD',
    description: 'Bringing application code, cloud infrastructure, and delivery configuration into one project.',
    url: 'https://github.com/khimkhum/vprofile-full',
    technologies: ['AWS', 'Terraform', 'Docker', 'Kubernetes', 'Helm', 'GitHub Actions', 'Argo CD', 'Java', 'Maven'],
    details: [
      'Organized a Java/Maven application alongside Docker configurations, Terraform infrastructure, and Kubernetes manifests.',
      'Created infrastructure configurations for AWS resources and workflows for application builds and code quality checks.',
      'Prepared Helm charts and Argo CD manifests for Kubernetes deployment and GitOps delivery.',
    ],
    flow: ['Code', 'Build', 'Registry', 'GitOps', 'Cluster'],
  },
  {
    id: '02',
    title: 'DevOps Demo App',
    category: 'Containerization & Kubernetes',
    description: 'A practical Flask application for exploring containers, persistence, and Kubernetes deployment.',
    url: 'https://github.com/khimkhum/devops-demo-app',
    technologies: ['Python', 'Flask', 'Docker', 'Docker Compose', 'PostgreSQL', 'Harbor', 'Kubernetes', 'k3d'],
    details: [
      'Containerized a Flask application with a multi-stage Dockerfile and non-root execution.',
      'Configured PostgreSQL persistence, health/readiness checks, and private Harbor image references by digest.',
      'Prepared Kubernetes resources, including StatefulSet and PVC, with application tests and database recovery checks.',
    ],
    flow: ['Flask', 'Docker', 'Harbor', 'k3d', 'Postgres'],
  },
];
