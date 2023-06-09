import Link from "next/link";
import { Inter } from "next/font/google";

const inter = Inter({ subsets: ["latin"] });

export default function Home() {
  return (
    <main className={inter.className}>
      <section className="bg-white">
        <div className="layout relative flex min-h-screen flex-col items-center justify-center py-12 text-center">
          <h1 className="text-xl">AWS Terraform Static Website Demo</h1>
          <p className="mt-2 text-sm text-gray-800">
            This is a demo of a static website deployed to AWS using Terraform.
          </p>

          <nav>
            <ul className="flex flex-col mt-4 space-y-2">
              <li>
                <Link className="underline" href="/about">
                  About
                </Link>
              </li>
            </ul>
          </nav>

          <footer className="absolute bottom-2 text-gray-700">
            By{" "}
            <a className="underline" href="https://azdanov.dev/">
              Anton Ždanov
            </a>
          </footer>
        </div>
      </section>
    </main>
  );
}
