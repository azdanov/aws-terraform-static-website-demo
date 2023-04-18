import './globals.css'

export const metadata = {
  title: 'AWS Terraform Static Website Demo',
  description: 'AWS Terraform Static Website Demo',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
